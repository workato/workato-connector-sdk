# typed: false
# frozen_string_literal: true

RSpec.describe 'oauth_refresh_automatic', :vcr do
  let(:connector) do
    Workato::Connector::Sdk::Connector.from_file('./spec/examples/oauth_refresh_automatic/connector.rb')
  end
  let(:settings) do
    Workato::Connector::Sdk::Settings.from_file('./spec/examples/oauth_refresh_automatic/settings.yaml').merge(
      access_token: access_token,
      refresh_token: refresh_token
    )
  end
  let(:access_token) { 'INVALID' }
  let(:refresh_token) do
    'eyJ0dCI6InAiLCJhbGciOiJIUzI1NiIsInR2IjoiMSJ9.eyJkIjoie1wiYVwiOjIyNzMwNjEsXCJpXCI6NTU0Nzc1MixcImNcIjo0NTk0NTkyLFwidlwiOlwiXCIsXCJ1XCI6NDY1NzE1NyxcInJcIjpcIlVTXCIsXCJzXCI6W1wiTlwiXSxcInpcIjpbXCJyc2hcIl0sXCJ0XCI6MTU0MTA3NDcyODAwMH0iLCJleHAiOjE1NDEwNzQ3MjgsImlhdCI6MTU0MTA3MTEyOH0.Jqqro5bsprV75fDDwptHXlMf_SyIYCpLoPS7hdQgDRA' # rubocop:disable Layout/LineLength
  end

  around do |example|
    Workato::Connector::Sdk::Connection.on_settings_update = lambda { |_message, _settings_before, refresher|
      refresher.call.tap do |new_settings|
        expect(new_settings).to eq(
          {
            access_token: 'eyJ0dCI6InAiLCJhbGciOiJIUzI1NiIsInR2IjoiMSJ9.eyJkIjoie1wiYVwiOjIyNzMwNjEsXCJpXCI6NTU0Nzc1MixcImNcIjo0NTk0NTkyLFwidlwiOlwiXCIsXCJ1XCI6NDY1NzE1NyxcInJcIjpcIlVTXCIsXCJzXCI6W1wiTlwiXSxcInpcIjpbXSxcInRcIjoxNTQxMDc3MTE4MDAwfSIsImV4cCI6MTU0MTA3NzExOCwiaWF0IjoxNTQxMDczNTE4fQ.WpNhXU4-f5rZp--IVKbjQsSR8fSmUZxWy2_SbZ7GmnE', # rubocop:disable Layout/LineLength
            refresh_token: 'eyJ0dCI6InAiLCJhbGciOiJIUzI1NiIsInR2IjoiMSJ9.eyJkIjoie1wiYVwiOjIyNzMwNjEsXCJpXCI6NTU0Nzc1MixcImNcIjo0NTk0NTkyLFwidlwiOlwiXCIsXCJ1XCI6NDY1NzE1NyxcInJcIjpcIlVTXCIsXCJzXCI6W1wiTlwiXSxcInpcIjpbXCJyc2hcIl0sXCJ0XCI6MTU0MTA3NzExODAwMH0iLCJleHAiOjE1NDEwNzcxMTgsImlhdCI6MTU0MTA3MzUxOH0.VMea1_neRzzZG-ZJzWZwJse3zqOD_pJjrDdXLAPHl7E', # rubocop:disable Layout/LineLength
            domain: 'https://www.example.com',
            client_id: 'zXkWHvok',
            client_secret: 'KlXvpJqyFEmymODgJa6kHKUATpSUS2BA07LHsi22ynKn29lqAi970EYkBNjPtkDh',
            token_type: 'Bearer'
          }.with_indifferent_access
        )
      end
    }

    example.call

    Workato::Connector::Sdk::Connection.on_settings_update = nil
  end

  it 'refreshes token' do
    output = connector.actions.test_action.execute(settings)
    expect(output['success']).to be_truthy
  end

  it 'raises error for acquires token' do
    expect { connector.connection.authorization.acquire }
      .to raise_error(Workato::Connector::Sdk::InvalidDefinitionError)
  end

  context 'when refresh token is blank' do
    let(:refresh_token) { '' }

    it 'asks for it' do
      expect { connector.actions.test_action.execute(settings) }
        .to raise_error(Workato::Connector::Sdk::NotImplementedError)
    end
  end
end
