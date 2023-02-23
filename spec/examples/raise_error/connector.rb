# typed: false
# frozen_string_literal: true

{
  title: 'Test custom connector raising exception',

  test: lambda do
    {}
  end,

  actions: {
    action_with_own_raise: {
      execute: lambda do
        error('custom test error')
      end
    },

    action_with_error: {
      execute: lambda do
        nil + 1
      end
    },

    action_with_own_raise_in_after_response: {
      execute: lambda do
        get('http://localhost/test_for_raise_in_after_response').response_format_raw.after_response do
          error('error from after_response')
        end
      end
    }
  }
}
