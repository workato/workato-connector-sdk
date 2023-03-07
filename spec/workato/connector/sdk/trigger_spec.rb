# typed: false
# frozen_string_literal: true

module Workato::Connector::Sdk
  RSpec.describe Trigger do
    around do |example|
      Timecop.freeze { example.run }
    end

    subject(:trigger) { described_class.new(trigger: trigger_definition) }

    describe '#poll' do
      let(:trigger_definition) { with_poll }

      it 'returns result' do
        settings = { a: :b }
        input = { c: :d }
        closure = 1.minute.ago
        extended_input_schema = { e: :f }
        extended_output_schema = { g: :h }

        output = trigger.poll_page(settings, input, closure, [extended_input_schema], [extended_output_schema])

        expect(output).to eq({
          events: [{
            connection: settings,
            input: input,
            closure: 1.minute.ago,
            extended_input_schema: [extended_input_schema.with_indifferent_access],
            extended_output_schema: [extended_output_schema.with_indifferent_access]
          }],
          can_poll_more: true,
          next_poll: 1.minute.from_now
        }.with_indifferent_access)
      end
    end

    describe 'poll' do
      let(:trigger_definition) { with_poll }

      it 'returns result of multiples polls' do
        settings = { a: :b }
        input = { c: :d }
        closure = 1.minute.ago
        extended_input_schema = { e: :f }
        extended_output_schema = { g: :h }

        output = trigger.poll(settings, input, closure, [extended_input_schema], [extended_output_schema])

        expect(output).to eq({
          events: [
            {
              connection: settings,
              input: input,
              closure: 1.minute.from_now,
              extended_input_schema: [extended_input_schema.with_indifferent_access],
              extended_output_schema: [extended_output_schema.with_indifferent_access]
            },
            {
              connection: settings,
              input: input,
              closure: 1.minute.ago,
              extended_input_schema: [extended_input_schema.with_indifferent_access],
              extended_output_schema: [extended_output_schema.with_indifferent_access]
            }
          ],
          can_poll_more: false,
          next_poll: 1.minute.from_now
        }.with_indifferent_access)
      end
    end

    describe 'webhook_notification' do
      let(:trigger_definition) { with_webhooks }

      it 'returns result' do
        payload = { a: :b }
        input = { c: :d }
        eis = { e: :f }
        eos = { g: :h }
        headers = { i: :j }
        params = { k: :l }
        settings = { m: :n }
        wso = { o: :p }

        output = trigger.webhook_notification(input, payload, [eis], [eos], headers, params, settings, wso)

        expect(output).to eq(
          {
            input: input.with_indifferent_access,
            payload: payload,
            extended_input_schema: [eis.with_indifferent_access],
            extended_output_schema: [eos.with_indifferent_access],
            headers: headers.with_indifferent_access,
            params: params.with_indifferent_access,
            settings: settings.with_indifferent_access,
            webhook_subscribe_output: wso.with_indifferent_access
          }
        )
      end

      context 'with HTTP request' do
        let(:trigger_definition) do
          {
            webhook_notification: lambda do
              get('http://localhost:3000')
            end
          }
        end

        it 'raises error' do
          expect { trigger.webhook_notification }.to raise_error(NoMethodError, /undefined method `get'/)
        end
      end

      context 'with method call' do
        subject(:trigger) do
          described_class.new(
            trigger: {
              webhook_notification: lambda do
                call('foo')
              end
            },
            methods: {
              foo: -> {}
            }
          )
        end

        it 'raises error' do
          expect { trigger.webhook_notification }.to raise_error(NoMethodError, /undefined method `call'/)
        end
      end

      context 'with connector-wide settings' do
        subject(:trigger) do
          described_class.new(trigger: trigger_definition, connection: Connection.new(settings: settings))
        end

        let(:settings) { { foo: :bar }.with_indifferent_access }
        let(:trigger_definition) { with_webhooks }

        it 'returns result' do
          output = trigger.webhook_notification

          expect(output).to include(settings: settings)
        end
      end
    end

    describe 'webhook_subscribe' do
      let(:trigger_definition) { with_webhooks }

      it 'returns result' do
        webhook_url = 'http://localhost:3000'
        settings = { a: :b }
        input = { c: :d }
        recipe_id = SecureRandom.uuid

        output = trigger.webhook_subscribe(webhook_url, settings, input, recipe_id)

        expect(output).to eq({
          webhook_url: webhook_url,
          connection: settings.with_indifferent_access,
          input: input.with_indifferent_access,
          recipe_id: recipe_id,
          subscribed: true
        }.with_indifferent_access)
      end

      context 'with expires_at' do
        let(:trigger_definition) do
          {
            webhook_subscribe: lambda do
              [{ subscribed: true }, 1.minute.from_now]
            end
          }
        end

        it 'returns result' do
          output = trigger.webhook_subscribe

          expect(output).to contain_exactly(
            { subscribed: true }.with_indifferent_access,
            a_kind_of(ActiveSupport::TimeWithZone)
          )
        end
      end
    end

    describe 'webhook_unsubscribe' do
      let(:trigger_definition) { with_webhooks }

      it 'returns result' do
        webhook_subscribe_output = {
          webhook_id: SecureRandom.uuid
        }

        output = trigger.webhook_unsubscribe(webhook_subscribe_output)

        expect(output).to eq({
          webhook_subscribe_output: webhook_subscribe_output.with_indifferent_access
        }.with_indifferent_access)
      end
    end

    private

    def with_poll
      {
        poll: lambda do |connection, input, closure, extended_input_schema, extended_output_schema|
          {
            events: {
              connection: connection,
              input: input,
              closure: closure,
              extended_input_schema: extended_input_schema,
              extended_output_schema: extended_output_schema
            },
            can_poll_more: closure < now,
            next_poll: 1.minute.from_now
          }
        end
      }
    end

    def with_webhooks
      {
        webhook_notification: lambda do |input, payload, eis, eos, headers, params, settings, wso|
          {
            input: input,
            payload: payload,
            extended_input_schema: eis,
            extended_output_schema: eos,
            headers: headers,
            params: params,
            settings: settings,
            webhook_subscribe_output: wso
          }
        end,

        webhook_subscribe: lambda do |webhook_url, connection, input, recipe_id|
          {
            webhook_url: webhook_url,
            connection: connection,
            input: input,
            recipe_id: recipe_id,
            subscribed: true
          }
        end,

        webhook_unsubscribe: lambda do |webhook_subscribe_output|
          {
            webhook_subscribe_output: webhook_subscribe_output
          }
        end
      }
    end
  end
end
