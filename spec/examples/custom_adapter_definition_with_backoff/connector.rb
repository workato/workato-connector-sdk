# typed: false
# frozen_string_literal: true

{
  methods: {
    get_error_code: lambda do |input|
      {
        '400' => 'http://www.mocky.io/v2/5e212e7d2f0000440077d4a8',
        '408' => 'http://www.mocky.io/v2/5e2137332f00004e0077d4c9',
        '500' => 'http://www.mocky.io/v2/5e21390b2f0000780077d4cc',
        '429' => 'http://www.mocky.io/v2/5e213c9b2f0000570077d4de',
        '502' => 'http://www.mocky.io/v2/5e2139d42f00004e0077d4d0',
        'error_message' => 'http://www.mocky.io/v2/5e2147b62f0000670077d50f',
        'plain_error' => 'http://www.mocky.io/v2/5e2147902f0000780077d50e'
      }.fetch(input)
    end
  },

  actions: {
    test_single_400_code_3_retry_get_method: {
      execute: lambda { |_connection, _input|
        {
          results: get(call(:get_error_code, '400'))
        }
      },
      retry_on_response: [400], # contains error codes and error message match rules
      retry_on_request: ['GET'],
      max_retries: 3
    },

    test_single_400_code_no_retry_get_method: {
      execute: lambda { |_connection, _input|
        {
          results: get(call(:get_error_code, '400'))
        }
      },
      retry_on_request: ['GET'],
      max_retries: 3
    },

    test_no_code_2_retry_get_method: {
      execute: lambda { |_connection, _input|
        {
          results: get(call(:get_error_code, '408'))
        }
      },
      retry_on_response: //,
      retry_on_request: ['GET'],
      max_retries: 2
    },

    test_double_408_code_2_retry_get_method: {
      execute: lambda { |_connection, _input|
        {
          results: get(call(:get_error_code, '408'))
        }
      },
      retry_on_response: [408, 500], # contains error codes and error message match rules
      retry_on_request: ['GET'],
      max_retries: 2
    },

    test_default_code_3_retry_get_method: {
      execute: lambda { |_connection, _input|
        {
          results: get(call(:get_error_code, '500'))
        }
      },
      retry_on_response: //,  # contains error codes and error message match rules
      retry_on_request: ['GET'],
      max_retries: 3
    },

    custom_http: {
      execute: lambda { |_connection, input|
        {
          results: get(input['url'])
        }
      },
      retry_on_response: 500,
      retry_on_request: %i[GET HEAD],
      max_retries: 3
    }
  }
}
