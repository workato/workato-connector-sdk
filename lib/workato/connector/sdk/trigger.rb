# frozen_string_literal: true

require 'securerandom'

module Workato
  module Connector
    module Sdk
      class Trigger < Operation
        using BlockInvocationRefinements

        def initialize(trigger:, connection: {}, methods: {}, settings: {}, object_definitions: nil)
          super(
            operation: trigger,
            connection: connection,
            methods: methods,
            settings: settings,
            object_definitions: object_definitions
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
          output[:events] = ::Array.wrap(output[:events]).reverse!.uniq(&trigger[:dedup])
          output[:next_poll] = output[:next_poll].presence || closure
          output
        end

        def poll(settings = nil, input = {}, closure = nil, extended_input_schema = [], extended_output_schema = [])
          events = []

          loop do
            output = poll_page(settings, input, closure, extended_input_schema, extended_output_schema)
            events = output[:events] + events
            closure = output[:next_poll]

            break unless output[:can_poll_more]
          end

          {
            events: events.uniq(&trigger[:dedup]),
            can_poll_more: false,
            next_poll: closure
          }.with_indifferent_access
        end

        def dedup(input = {})
          trigger[:dedup].call(input)
        end

        def webhook_notification(input = {}, payload = {}, extended_input_schema = [],
                                 extended_output_schema = [], headers = {}, params = {})
          Dsl::WithDsl.execute(
            input.with_indifferent_access,
            payload.with_indifferent_access,
            extended_input_schema.map(&:with_indifferent_access),
            extended_output_schema.map(&:with_indifferent_access),
            headers.with_indifferent_access,
            params.with_indifferent_access,
            &trigger[:webhook_notification]
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

        def webhook_unsubscribe(webhook_subscribe_output = {})
          webhook_unsubscribe_proc = trigger[:webhook_unsubscribe]
          execute(nil, webhook_subscribe_output) do |_connection, input|
            instance_exec(input, &webhook_unsubscribe_proc)
          end
        end

        def invoke(input = {}, payload = {}, headers = {}, params = {})
          extended_schema = extended_schema(nil, input)
          config_schema = Schema.new(schema: config_fields_schema)
          input_schema = Schema.new(schema: extended_schema[:input])
          output_schema = Schema.new(schema: extended_schema[:output])

          input = apply_input_schema(input, config_schema + input_schema)
          output = if webhook_notification?
                     webhook_notification(input, payload, input_schema, output_schema, headers, params)
                   else
                     poll(nil, input, nil, input_schema, output_schema)
                   end
          output[:events].each do |event|
            apply_output_schema(event, output_schema)
          end

          output
        end

        private

        alias trigger operation

        def webhook_notification?
          trigger[:webhook_notification].present?
        end
      end
    end
  end
end
