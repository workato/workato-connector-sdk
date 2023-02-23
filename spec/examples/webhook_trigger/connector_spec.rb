# typed: false
# frozen_string_literal: true

RSpec.describe 'poll_trigger', :vcr do
  let(:connector) do
    Workato::Connector::Sdk::Connector.from_file('./spec/examples/webhook_trigger/connector.rb')
  end
  let(:settings) do
    { user: 'user', password: 'password' }
  end

  describe 'webhook_subscribe' do
    it 'returns result' do
      webhook_url = 'http://example.com/webhooks'

      output = connector.triggers.test_trigger.webhook_subscribe(webhook_url, settings)

      expect(output).to eq({
        webhook_id: 1
      }.with_indifferent_access)
    end
  end

  describe 'webhook_unsubscribe' do
    it 'returns result' do
      subscribe_output = { webhook_id: '1' }

      output = connector.triggers.test_trigger.webhook_unsubscribe(subscribe_output)

      expect(output).to eq({
        success: true
      }.with_indifferent_access)
    end
  end

  describe 'webhook_notification' do
    it 'returns result' do
      payload = {
        'id' => '1000',
        'post' => {
          'id' => 1,
          'title' => 'Post #1'
        }
      }

      output = connector.triggers.test_trigger.webhook_notification({}, payload)

      expect(output).to eq({
        id: 1,
        title: 'Post #1'
      }.with_indifferent_access)
    end
  end
end
