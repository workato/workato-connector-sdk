# typed: false
# frozen_string_literal: true

{
  title: 'Test custom connector with table lookup',

  actions: {
    action_with_lookup_table: {
      execute: lambda do |_connection, input|
        lookup('CSV Table', input[:q])
      end
    }
  }
}
