# typed: false
# frozen_string_literal: true

{
  connection: {
    # Optional. Accepts an array of hashes. Each hash in this array corresponds to a separate input field.
    # To know more about how to define input fields in Workato
    # https://docs.workato.com/developing-connectors/sdk/sdk-reference/schema.html
    fields: [],

    authorization: {
      # basic_auth
      # api_key
      # oauth2  Used only for OAuth2 Auth Code Grant flows
      type: 'custom_auth',

      # Defines what authentication parameters Workato should add to subsequent HTTP requests in the connector.
      apply: ->(connection) {},

      # Required if type is "custom_auth". Optional if type is "oauth2"
      acquire: ->(connection) {},

      # Optional, If not defined, will default to one attempt at re-acquiring
      # credentials for all errors.
      refresh_on: [401, /Unauthorized/],

      # Optional, This function will be executed if we receive a non 2XX response in any API request or if the
      # refresh_on signal is triggered. This is used to obtain new access tokens. If this is not defined, Workato
      # attempts to use the standard OAuth2 refresh mechanism where possible or reruns the acquire lambda function.
      refresh: ->(connection) {},

      # Optional, Tells Workato when to raise an error due to a signal in the response
      # to a request. This accepts an array of integers which are matched to HTTP response codes or Regex expressions
      # which are matched on the response body.
      detect_on: [401, /Unauthorized/],

      # Required if type is "oauth2". Ignored otherwise.
      # Defines the client_id to use in Authorization URL and Token URL requests
      client_id: ->(connection) {},

      # Required if type is "oauth2" and acquire is not defined. Ignored otherwise.
      # Defines the client_secret to use in Token URL requests
      client_secret: ->(connection) {},

      # Required if type is "oauth2". Ignored otherwise.
      # Denotes the authorization URL that users should be sent to in OAuth2 Auth code grant flow.
      authorization_url: ->(connection) {},

      # Required if type is "oauth2" and acquire is not defined. Ignored otherwise.
      # Denotes the token URL that used to receive an access_token
      token_url: ->(connection) {}
    },

    # Optional, but recommended.
    # Defines the base URI for all future HTTP requests.
    base_uri: ->(connection) {}
  },

  test: lambda do |connection, input|
    {}.merge!(connection).merge!(input)
  end,

  actions: {
    foo: {
      execute: lambda do |_connection, _input, _extended_input_schema, _extended_output_schema|
        'Hello, World!'
      end,

      # Used in conjunction with retry_on_request: and max_retries:
      # https://docs.workato.com/developing-connectors/sdk/sdk-reference/actions.html#retry-on-response
      retry_on_response: [500, /error/],

      # Used in conjunction with retry_on_request: and max_retries:
      # https://docs.workato.com/developing-connectors/sdk/sdk-reference/actions.html#retry-on-request
      retry_on_request: %w[GET HEAD],

      # Used in conjunction with retry_on_request: and max_retries:
      # https://docs.workato.com/developing-connectors/sdk/sdk-reference/actions.html#max-retries
      max_retries: 2
    },
    bar: {
      execute: lambda do |_connection, _input, _extended_input_schema, _extended_output_schema|
        get('https://ifconfig.me/all.json')['ip_addr']
      end
    }
  },

  methods: {}
}
