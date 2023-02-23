# typed: false
# frozen_string_literal: true

{
  title: 'Test custom connector with requests chained in after_response',

  test: lambda do
    {}
  end,

  actions: {
    action_with_chained_requests: {
      execute: lambda do
        get('http://localhost/test_request_one').response_format_raw.after_response do
          get('http://localhost/test_request_two').response_format_raw.after_response do
            get('http://localhost/test_request_three')
          end
        end
      end
    }
  }
}
