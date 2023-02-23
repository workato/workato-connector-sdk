# typed: false
# frozen_string_literal: true

{
  connection: {
    authorization: {
      type: 'oauth2',

      authorization_url: lambda do |connection|
        "#{connection[:domain]}/oauth2/authorize?response_type=code"
      end,

      client_id: lambda do |connection|
        connection['client_id']
      end,

      client_secret: lambda do |connection|
        connection['client_secret']
      end,

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
      end,

      acquire: lambda do |connection, auth_code, redirect_url|
        response = post("#{connection[:domain]}/oauth2/token").payload(
          client_id: connection['client_id'],
          client_secret: connection['client_secret'],
          grant_type: 'authorization_code',
          code: auth_code,
          redirect_uri: redirect_url
        ).request_format_www_form_urlencoded

        [
          {
            access_token: response['access_token'],
            refresh_token: response['refresh_token']
          },
          1,
          {
            expired: nil
          }
        ]
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
