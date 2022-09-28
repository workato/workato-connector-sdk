# typed: strict
# frozen_string_literal: true

require 'securerandom'

module Workato
  module Connector
    module Sdk
      module SorbetTypes
        WebhookSubscribeOutputHash = T.type_alias { T::Hash[T.any(String, Symbol), T.untyped] }

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
        using BlockInvocationRefinements

        sig do
          params(
            trigger: SorbetTypes::SourceHash,
            methods: SorbetTypes::SourceHash,
            connection: Connection,
            object_definitions: T.nilable(ObjectDefinitions)
          ).void
        end
        def initialize(trigger:, methods: {}, connection: Connection.new, object_definitions: nil)
          super(
            operation: trigger,
            connection: connection,
            methods: methods,
            object_definitions: object_definitions
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
            instance_exec(connection, payload[:input], payload[:closure], eis, eos, &poll_proc)
          end
          output.with_indifferent_access
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
            webhook_subscribe_output: SorbetTypes::WebhookSubscribeOutputHash
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
          output = Dsl::WithDsl.execute(
            connection,
            input.with_indifferent_access,
            payload,
            Array.wrap(extended_input_schema).map(&:with_indifferent_access),
            Array.wrap(extended_output_schema).map(&:with_indifferent_access),
            headers.with_indifferent_access,
            params.with_indifferent_access,
            connection.settings,
            webhook_subscribe_output.with_indifferent_access,
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
          ).returns(
            SorbetTypes::WebhookSubscribeOutputHash
          )
        end
        def webhook_subscribe(webhook_url = '', settings = nil, input = {}, recipe_id = SecureRandom.uuid)
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

        sig { params(webhook_subscribe_output: SorbetTypes::WebhookSubscribeOutputHash).returns(T.untyped) }
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
            webhook_subscribe_output: SorbetTypes::WebhookSubscribeOutputHash
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
      end
    end
  end
end
