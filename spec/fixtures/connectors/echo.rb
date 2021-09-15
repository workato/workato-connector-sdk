# frozen_string_literal: true

{
  test: lambda do |connection, input|
    {
      connection: connection,
      input: input
    }
  end,

  actions: {
    echo_action: {
      execute: lambda do |connection, input, eis, eos|
        {
          connection: connection,
          input: input,
          extended_input_schema: eis,
          extended_output_schema: eos
        }
      end,

      input_fields: lambda do |object_definitions, connection, config_fields|
        {
          object_definitions: object_definitions,
          connection: connection,
          config_fields: config_fields
        }
      end,

      output_fields: lambda do |object_definitions, connection, config_fields|
        {
          object_definitions: object_definitions,
          connection: connection,
          config_fields: config_fields
        }
      end,

      sample_output: lambda do |connection, input|
        {
          connection: connection,
          input: input
        }
      end
    }
  },

  triggers: {
    echo_trigger: {
      poll: lambda do |connection, input, closure|
        {
          events: {
            connection: connection,
            input: input,
            closure: closure
          },
          can_poll_more: false,
          next_poll: 1.minute.from_now
        }
      end,

      dedup: lambda do |record|
        { record: record }
      end,

      webhook_notification: lambda do |input, payload, eis, eos, headers, params|
        {
          input: input,
          payload: payload,
          extended_input_schema: eis,
          extended_output_schema: eos,
          headers: headers,
          params: params
        }
      end,

      webhook_subscribe: lambda do |webhook_url, connection, input, recipe_id|
        {
          webhook_url: webhook_url,
          connection: connection,
          input: input,
          recipe_id: recipe_id,
          subscribed: true
        }
      end,

      webhook_unsubscribe: lambda do |webhook_subscribe_output|
        {
          webhook_subscribe_output: webhook_subscribe_output
        }
      end
    }
  },

  methods: {
    echo_method2: lambda do |a, b|
      {
        a: a,
        b: b
      }
    end,
    echo_method3: lambda do |a, b, c|
      {
        a: a,
        b: b,
        c: c
      }
    end,
    echo_method4: lambda do |a, b, c, d|
      {
        a: a,
        b: b,
        c: c,
        d: d
      }
    end
  },

  pick_lists: {
    static: lambda do
      {
        static: true
      }
    end,

    with_connection: lambda do |connection|
      {
        connection: connection
      }
    end,

    with_kwargs: lambda do |connection, arg1: 1, arg2: 2, arg3: 3|
      {
        connection: connection,
        arg1: arg1,
        arg2: arg2,
        arg3: arg3
      }
    end
  },

  object_definitions: {
    echo: {
      fields: lambda do |connection, config_fields|
        {
          connection: connection,
          config_fields: config_fields
        }
      end
    }
  }
}
