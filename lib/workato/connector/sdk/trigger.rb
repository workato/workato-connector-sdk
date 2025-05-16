# typed: strict
# frozen_string_literal: true

require 'securerandom'

module Workato
  module Connector
    module Sdk
      module SorbetTypes
        WebhookSubscribeClosureHash = T.type_alias { T::Hash[T.any(String, Symbol), T.untyped] }

        WebhookSubscribeOutput = T.type_alias do
          T.any(
            WebhookSubscribeClosureHash,
            [WebhookSubscribeClosureHash, T.nilable(T.any(Time, ActiveSupport::TimeWithZone))]
          )
        end

        WebhookNotificationPayload = T.type_alias { T.untyped }

        TriggerEventHash = T.type_alias { T::Hash[T.untyped, T.untyped] }

        WebhookNotificationOutputHash = T.type_alias { T.any(T::Array[TriggerEventHash], TriggerEventHash) }

        PollOutputHash = T.type_alias do
          {
            'events' => T::Array[TriggerEventHash],
            'can_poll_more' => T.nilable(T::Boolean),
            'next_poll' => T.untyped
          }
        end
      end

      class Trigger < Operation
        using BlockInvocationRefinements # rubocop:disable Sorbet/Refinement core SDK feature

        sig do
          params(
            trigger: SorbetTypes::SourceHash,
            methods: SorbetTypes::SourceHash,
            connection: Connection,
            object_definitions: T.nilable(ObjectDefinitions),
            streams: Streams
          ).void
        end
        def initialize(trigger:, methods: {}, connection: Connection.new, object_definitions: nil,
                       streams: ProhibitedStreams.new)
          super(
            operation: trigger,
            connection: connection,
            methods: methods,
            object_definitions: object_definitions,
            streams: streams
          )
        end

        sig do
          params(
            settings: T.nilable(SorbetTypes::SettingsHash),
            input: SorbetTypes::OperationInputHash,
            closure: T.untyped,
            extended_input_schema: SorbetTypes::OperationSchema,
            extended_output_schema: SorbetTypes::OperationSchema
          ).returns(
            SorbetTypes::PollOutputHash
          )
        end
        def poll_page(settings = nil, input = {}, closure = nil, extended_input_schema = [],
                      extended_output_schema = [])
          poll_proc = trigger[:poll]
          output = execute(
            settings,
            { input: input, closure: closure },
            extended_input_schema,
            extended_output_schema
          ) do |connection, payload, eis, eos|
            instance_exec(connection, payload[:input], payload[:closure], eis, eos, &poll_proc) || {}
          end

          unless T.unsafe(output).is_a?(::Hash)
            Kernel.raise Workato::Connector::Sdk::InvalidTriggerPollOutputError
          end

          output[:events] = Array.wrap(output[:events])
                                 .reverse!
                                 .map! { |event| ::Hash.try_convert(event) || event }
          output[:next_poll] = output[:next_poll].presence || closure
          output
        end

        sig do
          params(
            settings: T.nilable(SorbetTypes::SettingsHash),
            input: SorbetTypes::OperationInputHash,
            closure: T.untyped,
            extended_input_schema: SorbetTypes::OperationSchema,
            extended_output_schema: SorbetTypes::OperationSchema
          ).returns(
            SorbetTypes::PollOutputHash
          )
        end
        def poll(settings = nil, input = {}, closure = nil, extended_input_schema = [], extended_output_schema = [])
          events = T.let([], T::Array[SorbetTypes::TriggerEventHash])

          loop do
            output = poll_page(settings, input, closure, extended_input_schema, extended_output_schema)
            events = output[:events] + events
            closure = output[:next_poll]

            break unless output[:can_poll_more]
          end

          {
            events: events,
            can_poll_more: false,
            next_poll: closure
          }.with_indifferent_access
        end

        sig { params(input: SorbetTypes::TriggerEventHash).returns(T.untyped) }
        def dedup(input = {})
          trigger[:dedup].call(input)
        end

        sig do
          params(
            input: SorbetTypes::OperationInputHash,
            payload: SorbetTypes::WebhookNotificationPayload,
            extended_input_schema: SorbetTypes::OperationSchema,
            extended_output_schema: SorbetTypes::OperationSchema,
            headers: T::Hash[T.any(String, Symbol), T.untyped],
            params: T::Hash[T.any(String, Symbol), T.untyped],
            settings: T.nilable(SorbetTypes::SettingsHash),
            webhook_subscribe_output: T.nilable(SorbetTypes::WebhookSubscribeClosureHash)
          ).returns(
            SorbetTypes::WebhookNotificationOutputHash
          )
        end
        def webhook_notification(
          input = {},
          payload = {},
          extended_input_schema = [],
          extended_output_schema = [],
          headers = {},
          params = {},
          settings = nil,
          webhook_subscribe_output = {}
        )
          connection.merge_settings!(settings) if settings
          output = global_dsl_context.execute(
            Utilities::HashWithIndifferentAccess.wrap(input),
            payload,
            Array.wrap(extended_input_schema).map { |i| Utilities::HashWithIndifferentAccess.wrap(i) },
            Array.wrap(extended_output_schema).map { |i| Utilities::HashWithIndifferentAccess.wrap(i) },
            Utilities::HashWithIndifferentAccess.wrap(headers),
            Utilities::HashWithIndifferentAccess.wrap(params),
            connection.settings,
            Utilities::HashWithIndifferentAccess.wrap(webhook_subscribe_output),
            &trigger[:webhook_notification]
          )
          if output.is_a?(::Array)
            output.map! { |event| ::Hash.try_convert(event) || event }
          else
            ::Hash.try_convert(output) || output
          end
        end

        sig do
          params(
            webhook_url: String,
            settings: T.nilable(SorbetTypes::SettingsHash),
            input: SorbetTypes::OperationInputHash,
            recipe_id: String
          ).returns(SorbetTypes::WebhookSubscribeOutput)
        end
        def webhook_subscribe(webhook_url = '', settings = nil, input = {}, recipe_id = recipe_id!)
          webhook_subscribe_proc = trigger[:webhook_subscribe]
          execute(settings, { input: input, webhook_url: webhook_url, recipe_id: recipe_id }) do |connection, payload|
            instance_exec(
              payload[:webhook_url],
              connection,
              payload[:input],
              payload[:recipe_id],
              &webhook_subscribe_proc
            )
          end
        end

        sig { params(webhook_subscribe_output: SorbetTypes::WebhookSubscribeClosureHash).returns(T.untyped) }
        def webhook_unsubscribe(webhook_subscribe_output = {})
          webhook_unsubscribe_proc = trigger[:webhook_unsubscribe]
          execute(nil, webhook_subscribe_output) do |_connection, input|
            instance_exec(input, &webhook_unsubscribe_proc)
          end
        end

        sig do
          params(
            input: SorbetTypes::OperationInputHash,
            payload: T::Hash[T.any(String, Symbol), T.untyped],
            headers: T::Hash[T.any(String, Symbol), T.untyped],
            params: T::Hash[T.any(String, Symbol), T.untyped],
            webhook_subscribe_output: T.nilable(SorbetTypes::WebhookSubscribeClosureHash)
          ).returns(
            T.any(SorbetTypes::WebhookNotificationOutputHash, SorbetTypes::PollOutputHash)
          )
        end
        def invoke(input = {}, payload = {}, headers = {}, params = {}, webhook_subscribe_output = {})
          extended_schema = extended_schema(nil, input)
          config_schema = Schema.new(schema: config_fields_schema)
          input_schema = Schema.new(schema: extended_schema[:input])
          output_schema = Schema.new(schema: extended_schema[:output])

          input = apply_input_schema(input, config_schema + input_schema)
          if webhook_notification?
            webhook_notification(
              input,
              payload,
              input_schema,
              output_schema,
              headers,
              params,
              nil,
              webhook_subscribe_output
            ).tap do |event|
              apply_output_schema(event, output_schema)
            end
          else
            output = poll(nil, input, nil, input_schema, output_schema)
            output[:events].each do |event|
              apply_output_schema(event, output_schema)
            end
            output
          end
        end

        private

        alias trigger operation

        sig { returns(T::Boolean) }
        def webhook_notification?
          trigger[:webhook_notification].present?
        end

        sig { returns(Dsl::WithDsl) }
        def global_dsl_context
          Dsl::WithDsl.new(connection, streams)
        end
      end
    end
  end
end
