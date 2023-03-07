# typed: false
# frozen_string_literal: false

{
  title: 'net',

  connection: {
    authorization: {
      type: 'none'
    }
  },

  test: lambda do
    true
  end,

  actions: {
    lookup_a_info: {
      execute: lambda do |_connection, _input|
        {
          output: workato.net.lookup('localhost', 'A')
        }
      end
    },

    lookup_srv_info: {
      execute: lambda do |_connection, _input|
        {
          output: workato.net.lookup('_ldap._tcp.google.com', 'SRV')
        }
      end
    }
  }
}
