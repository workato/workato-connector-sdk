# frozen_string_literal: true

{
  connection: {
    authorization: {
      type: 'oauth2',

      apply: lambda do |connection, access_token|
        headers(Authorization: "#{connection['token_type']} #{access_token}")
      end,

      refresh_on: 401,

      refresh: lambda do |connection, refresh_token|
        post("#{connection[:domain]}/oauth2/token").payload(
          client_id: connection[:client_id],
          client_secret: connection['client_secret'],
          refresh_token: refresh_token,
          grant_type: 'refresh_token'
        ).request_format_www_form_urlencoded
      end
    },

    base_uri: lambda do |connection|
      connection['domain']
    end
  },

  actions: {
    test_action: {
      execute: lambda do
        get('/test')
      end
    }
  }
}
