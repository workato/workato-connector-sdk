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
    end
  },

  actions: {
    test_action: {
      execute: lambda do |_connection, input|
        call(:test_method, input)
      end
    }
  }
}
