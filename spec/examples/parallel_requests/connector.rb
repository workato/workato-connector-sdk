# typed: false
# frozen_string_literal: true

{
  title: 'With parallel requests',

  connection: {
    type: 'custom_auth',

    authorization: {
      acquire: lambda do |_connection|
        { token: 'abcd' }
      end,

      apply: lambda do |connection|
        params(token: connection[:token]) if connection.key?(:token)
      end,

      refresh_on: [401]
    }
  },

  actions: {
    test_action: {
      execute: lambda do |_connection, input|
        requests = input['urls'].map do |url|
          get(url).response_format_raw
        end

        {
          result: parallel(requests, threads: 10, requests_per_period: 1, period: 60)
        }
      end
    },

    test_action_with_json_parse_error: {
      execute: lambda do
        requests = [
          get('http://localhost/json'),
          get('http://localhost/a')
        ]

        {
          result: parallel(requests, threads: 10, requests_per_period: 1, period: 60)
        }
      end
    },

    test_action_with_error: {
      execute: lambda do
        requests = [
          get('http://localhost/json'),
          get('http://localhost/a').response_format_raw.after_response do
            error('OOOPs! Something went wrong')
          end,
          get('http://localhost/b').response_format_raw
        ]

        {
          result: parallel(requests, threads: 10, requests_per_period: 1, period: 60)
        }
      end
    }
  }
}
