# typed: false
# frozen_string_literal: true

{
  title: 'Test custom connector with reusable methods',

  connection: {
    authorization: {
      type: 'custom_auth',

      apply: lambda do |connection|
        user(connection[:user])
        password(connection[:password])
      end
    }
  },

  methods: {
    test_method: lambda do |input|
      get('https://httpbin.org/anything', input)['args']
    end,

    unexpected_type_error: :to_s
  },

  actions: {
    test_action: {
      execute: lambda do |_connection, input|
        call(:test_method, input)
      end
    },

    with_unexpected_type_error: {
      execute: lambda do
        call(:unexpected_type_error)
      end
    },

    with_undefined_method_error: {
      execute: lambda do
        call(:unknown)
      end
    }
  }
}
