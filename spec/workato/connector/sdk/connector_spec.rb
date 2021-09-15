# frozen_string_literal: true

module Workato::Connector::Sdk
  RSpec.describe Connector do
    subject(:connector) { described_class.new(connector_code) }

    it 'provides accessors for actions' do
      expect(connector.actions.test_action).to be_kind_of(Action)
      expect(connector.actions[:test_action]).to be_kind_of(Action)
      expect(connector.actions['test_action']).to be_kind_of(Action)
    end

    context 'when read from connector file' do
      subject(:connector) { described_class.from_file('./spec/fixtures/connectors/hello_world.rb') }

      it { is_expected.to be_kind_of(described_class) }
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
              puts 'Hello, World!'
            end
          }
        }
      }
    end
  end
end
