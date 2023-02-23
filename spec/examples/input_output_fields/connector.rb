# typed: false
# frozen_string_literal: true

{
  actions: {
    test_action: {
      input_fields: lambda do |object_definitions, connection, config_fields|
        {
          object_definitions: {
            event: object_definitions['event']
          },
          connection: connection,
          config_fields: config_fields,
          customer: get('http://httpbin.org/anything/object_definitions/customer')
        }
      end,
      output_fields: lambda do |object_definitions, connection, config_fields|
        [{
          object_definitions: {
            event: object_definitions['event']
          },
          connection: connection,
          config_fields: config_fields,
          customer: get('http://httpbin.org/anything/object_definitions/customer')
        }]
      end
    }
  },

  object_definitions: {
    event: {
      fields: lambda do |_connection, config_fields|
        response = get('http://httpbin.org/anything/object_definitions/event').params(config_fields)
        [response['args'].merge(name: 'type')]
      end
    },
    static: {
      fields: lambda do
        [{ name: 'id' }]
      end
    }
  }
}
