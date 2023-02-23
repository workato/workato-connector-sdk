# typed: false
# frozen_string_literal: true

module Workato::Connector::Sdk
  RSpec.describe Connector do
    subject(:connector) { described_class.new(connector_code) }

    it 'provides accessors for actions' do
      expect(connector.actions.test_action).to be_a(Action)
      expect(connector.actions[:test_action]).to be_a(Action)
      expect(connector.actions['test_action']).to be_a(Action)
    end

    it 'executes action' do
      expect(connector.actions.test_action({})).to eq('message' => 'Hello World!')
    end

    it 'executes poll trigger' do
      expect(connector.triggers.poll_trigger({})).to include(
        'events' => [
          { 'message' => 'Hello World from poll trigger!' }
        ]
      )
    end

    it 'executes webhook trigger' do
      expect(connector.triggers.webhook_trigger({})).to include(
        events: [
          { message: 'Hello World from webhook trigger!' }
        ]
      )
    end

    context 'when read from connector file' do
      subject(:connector) { described_class.from_file('./spec/fixtures/connectors/hello_world.rb') }

      it { is_expected.to be_a(described_class) }
    end

    describe '#test' do
      subject(:test) { connector.test(settings) }

      let(:settings) { { fizz: :buzz } }

      it { is_expected.to eq({ fizz: :buzz }.with_indifferent_access) }
    end

    private

    def connector_code
      @connector_code ||= {
        title: 'Test Workato::Connector::Sdk::Connector',

        test: lambda do |connection|
          connection
        end,

        actions: {
          test_action: {
            execute: lambda do
              { message: 'Hello World!' }
            end
          }
        },

        triggers: {
          poll_trigger: {
            poll: lambda do
              {
                events: [
                  { message: 'Hello World from poll trigger!' }
                ]
              }
            end
          },

          webhook_trigger: {
            webhook_notification: lambda do
              {
                events: [
                  { message: 'Hello World from webhook trigger!' }
                ]
              }
            end
          }
        }
      }
    end
  end
end
