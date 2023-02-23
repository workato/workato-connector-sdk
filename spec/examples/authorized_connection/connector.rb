# typed: false
# frozen_string_literal: true

{
  title: 'Custom auth test',

  connection: {
    authorization: {
      type: 'custom_auth',

      # How to get or refresh credentials. Context is same as an action's execute block.
      # The result will be merged into the connection hash.
      # Note: the apply (aka credentials) block will *not* be applied to any requests made here.
      acquire: lambda do |_connection|
        post('https://httpbin.org/anything').payload(user: 'user', password: 'password')['json']
      end,

      # Synonym of the credentials block: How to apply the credentials to an action/trigger/test request.
      apply: lambda do |connection|
        user(connection[:user])
        password(connection[:password])
      end,

      # Errors which signal the need to (re)acquire credentials
      # This is optional; if missing, any error will result in one attempt to re-authorize.
      refresh_on: [
        # Three ways to match:
        401, # Integer HTTP response code.
        'Unauthorized', # String that equals the whole body or whole title of the error response.
        /Unauthorized/, # Regex that matches with the body or title of the error response.
        /Invalid Password/ # The actual "signal" that we need to re-authorize in Test.
      ],

      # Some APIs don't signal errors with an explicit error response like a 401.  Instead
      # they return a 200 with payload that signals the error. This optional hook lets us
      # detect that and raise it as an exception, so that the refresh framework above can
      # match it.
      detect_on: [
        # Two ways to match: String (matches whole body of the response), and:
        /"error": ".*"/ # Regex that matches the body of the response.
      ]
    }
  },

  actions: {
    action_with_authorized_request: {
      execute: lambda do |connection|
        get('https://httpbin.org/basic-auth/user/password').merge(connection)
      end
    }
  }
}
