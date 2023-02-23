# typed: false
# frozen_string_literal: true

RSpec.describe 'authorized_connection', :vcr do
  let(:connector) do
    Workato::Connector::Sdk::Connector.from_file('./spec/examples/authorized_connection/connector.rb')
  end
  let(:settings) do
    Workato::Connector::Sdk::Settings.from_file('./spec/examples/authorized_connection/settings.yaml', connection_name)
  end

  context 'when connection settings is valid' do
    let(:connection_name) { 'My Valid Connection' }

    it 'makes request' do
      output = connector.actions.action_with_authorized_request.execute(settings)
      expect(output['authenticated']).to be_truthy
    end
  end

  context 'when connection settings is invalid' do
    let(:connection_name) { 'My Invalid Connection' }

    around do |example|
      Workato::Connector::Sdk::Connection.on_settings_update = lambda { |_, _, refresher|
        refresher.call.tap do |new_settings|
          expect(new_settings).to eq({ password: 'password', user: 'user' }.with_indifferent_access)
        end
      }

      example.call

      Workato::Connector::Sdk::Connection.on_settings_update = nil
    end

    it 'makes request' do
      output = connector.actions.action_with_authorized_request.execute(settings)
      expect(output['authenticated']).to be_truthy
    end
  end
end
