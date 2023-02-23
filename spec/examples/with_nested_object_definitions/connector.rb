# typed: false
# frozen_string_literal: true

{
  title: 'Nested Object Definitions',

  connection: {
    authorization: {
      type: 'none'
    }
  },

  test: lambda do |_connection|
    true
  end,

  object_definitions: {
    circular_reference_error: {
      fields: lambda do |_connection, _config_fields, object_definitions|
        {
          name: 'recursive_object_field',
          type: 'object',
          properties: object_definitions['circular_reference_error']
        }
      end
    },

    compound_type: {
      fields: lambda { |_connection, _config_fields, object_definitions|
        [
          {
            name: 'array_of_objects',
            type: 'array',
            of: 'object',
            properties: object_definitions['object_one']
          },
          {
            name: 'object_of_object',
            type: 'object',
            properties: object_definitions['object_two']
          }
        ]
      }
    },

    object_one: {
      fields: lambda {
        [
          { name: 'object_one_field' }
        ]
      }
    },

    object_two: {
      fields: lambda { |_connection, _config_fields, object_definitions|
        [
          { name: 'object_two_field' },
          {
            name: 'object_of_object_one',
            type: 'object',
            properties: object_definitions['object_one']
          }
        ]
      }
    },

    unresolved_error: {
      fields: lambda do |_connection, _config_fields, object_definitions|
        object_definitions['unknown']
      end
    }
  },

  actions: {
    test_action: {
      title: 'Test compound type',

      input_fields: lambda do |object_definitions|
        object_definitions['compound_type']
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['compound_type']
      end
    },

    with_recursive_definition: {
      input_fields: lambda do |object_definitions|
        object_definitions['recursive_object']
      end,

      execute: lambda do |_connection, input, input_schema, output_schema|
        {
          input: input,
          input_schema: input_schema,
          output_schema: output_schema
        }
      end,

      output_fields: lambda do |object_definitions|
        object_definitions['recursive_object']
      end
    }
  }
}
