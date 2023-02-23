# typed: false
# frozen_string_literal: true

{
  connection: {
    authorization: {
      type: 'custom_auth',

      apply: lambda do |settings|
        user(settings[:user])
        password(settings[:password])
      end
    },
    base_uri: lambda do
      'http://lvh.me:1080/'
    end
  },

  triggers: {
    test_trigger: {
      webhook_notification: lambda do |_input, payload, _eis, _eos, _headers, _params, _settings, _wso|
        payload['post']
      end,

      webhook_subscribe: lambda do |_webhook_url, _connection, _input, _recipe_id|
        response = post('/webhooks/subscribe')

        {
          webhook_id: response['id']
        }
      end,

      webhook_unsubscribe: lambda do |webhook_subscribe_output|
        post('/webhooks/unsubscribe').params('id' => webhook_subscribe_output[:id])
      end
    }
  }
}
