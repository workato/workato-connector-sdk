# typed: false
# frozen_string_literal: true

RSpec.describe 'multi_auth', :vcr do
  let(:connector) { Workato::Connector::Sdk::Connector.from_file('./spec/examples/multi_auth/connector.rb') }

  context 'when oauth2_manual' do
    let(:settings) do
      {
        auth_type: 'oauth2_manual',
        access_token: 'INVALID',
        refresh_token: 'eyJ0dCI6InAiLCJhbGciOiJIUzI1NiIsInR2IjoiMSJ9.eyJkIjoie1wiYVwiOjIyNzMwNjEsXCJpXCI6NTU0Nzc1MixcImNcIjo0NTk0NTkyLFwidlwiOlwiXCIsXCJ1XCI6NDY1NzE1NyxcInJcIjpcIlVTXCIsXCJzXCI6W1wiTlwiXSxcInpcIjpbXCJyc2hcIl0sXCJ0XCI6MTU0MTA3NDcyODAwMH0iLCJleHAiOjE1NDEwNzQ3MjgsImlhdCI6MTU0MTA3MTEyOH0.Jqqro5bsprV75fDDwptHXlMf_SyIYCpLoPS7hdQgDRA', # rubocop:disable Layout/LineLength
        domain: 'https://www.example.com',
        client_id: 'zXkWHvok',
        client_secret: 'KlXvpJqyFEmymODgJa6kHKUATpSUS2BA07LHsi22ynKn29lqAi970EYkBNjPtkDh',
        token_type: 'Bearer'
      }
    end

    it 'makes request' do
      output = connector.actions.test_oauth2.execute(settings)
      expect(output['success']).to be_truthy
    end

    it 'acquires token' do
      token, owner_id, other_settings = connector.connection.authorization.acquire(settings, 'C-bxv', 'http://localhost:45555/oauth/callback')
      expect(token).to eq('access_token' => 'ACCT-OizMaC', 'refresh_token' => 'REFT-Rumsbq')
      expect(owner_id).to eq(1)
      expect(other_settings).to eq('expired' => nil)
    end
  end

  context 'when oauth2_automatic' do
    let(:settings) do
      {
        auth_type: 'oauth2_automatic',
        access_token: 'INVALID',
        refresh_token: 'eyJ0dCI6InAiLCJhbGciOiJIUzI1NiIsInR2IjoiMSJ9.eyJkIjoie1wiYVwiOjIyNzMwNjEsXCJpXCI6NTU0Nzc1MixcImNcIjo0NTk0NTkyLFwidlwiOlwiXCIsXCJ1XCI6NDY1NzE1NyxcInJcIjpcIlVTXCIsXCJzXCI6W1wiTlwiXSxcInpcIjpbXCJyc2hcIl0sXCJ0XCI6MTU0MTA3NDcyODAwMH0iLCJleHAiOjE1NDEwNzQ3MjgsImlhdCI6MTU0MTA3MTEyOH0.Jqqro5bsprV75fDDwptHXlMf_SyIYCpLoPS7hdQgDRA', # rubocop:disable Layout/LineLength
        domain: 'https://www.example.com',
        client_id: 'zXkWHvok',
        client_secret: 'KlXvpJqyFEmymODgJa6kHKUATpSUS2BA07LHsi22ynKn29lqAi970EYkBNjPtkDh',
        token_type: 'Bearer'
      }
    end

    it 'makes request' do
      output = connector.actions.test_oauth2.execute(settings)
      expect(output['success']).to be_truthy
    end

    it 'raises error for acquires token' do
      expect { connector.connection.authorization.acquire }
        .to raise_error(Workato::Connector::Sdk::InvalidDefinitionError)
    end
  end

  context 'when basic_auth' do
    let(:settings) { { auth_type: 'basic_auth', user: 'user', password: 'password' } }

    it 'makes request' do
      output = connector.actions.test_basic_auth.execute(settings)
      expect(output['authenticated']).to be_truthy
    end
  end

  context 'when undefined auth type' do
    it 'raises error in runtime' do
      action = connector.actions.test_basic_auth # accessing action do not raise error

      expect { action.execute }.to raise_error(Workato::Connector::Sdk::UnresolvedMultiAuthOptionError)
    end
  end
end
