# typed: false
# frozen_string_literal: true

{
  title: 'Random Number',

  connection: {
    fields: [],

    authorization: {
      type: 'custom_auth'
    },

    base_uri: lambda do
      'https://csrng.net'
    end
  },

  test: lambda do |_connection|
    rand(1000)
  end,

  actions: {
    get_random_integer: {
      title: 'Get random Integer',
      subtitle: 'Get a random number from range',
      description: 'Get a random number from range',
      help: 'See https://csrng.net/ for details',

      input_fields: lambda do |_object_definitions|
        [
          {
            name: 'min',
            label: 'Min',
            type: 'integer',
            optional: true
          },
          {
            name: 'max',
            label: 'Max',
            type: 'integer',
            optional: true
          }
        ]
      end,

      execute: lambda do |_connection, input, _input_schema, _output_schema|
        min = input['min'].presence || 1
        error("Min must be a positive integer, got #{min}") unless call(:positive_integer?, min)
        max = input['max'].presence || 9_007_199_254_740_991
        error("Max must be a positive integer, got #{max}") unless call(:positive_integer?, max)
        error('Max must be greater or equal to min') if min.to_i > max.to_i

        req = get('https://csrng.net/csrng/csrng.php').params(min: min, max: max)
        req.after_response do |_code, body, _headers|
          if body[0]['status'] == 'success'
            { value: body[0]['random'] }
          else
            error(body[0]['reason'])
          end
        end
      end,

      output_fields: lambda do |_object_definitions|
        [
          {
            name: 'value',
            type: 'integer',
            label: 'Value'
          }
        ]
      end,

      sample_output: lambda do |_connection, _input|
        {
          value: 42
        }
      end
    }
  },

  methods: {
    positive_integer?: lambda do |value|
      int_value = value.to_i
      int_value.to_s == value.to_s && int_value > 0
    end
  }
}
