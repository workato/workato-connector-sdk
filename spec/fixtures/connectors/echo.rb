# typed: false
# frozen_string_literal: true

{
  connection: {
    base_uri: lambda do |connection|
      {
        connection: connection
      }.to_json
    end,

    authorization: {
      type: :oauth2,

      authorization_url: lambda do |connection|
        {
          connection: connection
        }.to_json
      end,

      token_url: lambda do |connection|
        {
          connection: connection
        }.to_json
      end,

      client_id: lambda do |connection|
        {
          connection: connection
        }.to_json
      end,

      client_secret: lambda do |connection|
        {
          connection: connection
        }.to_json
      end,

      acquire: lambda do |connection, oauth2_code, redirect_url|
        {
          connection: connection,
          oauth2_code: oauth2_code,
          redirect_url: redirect_url
        }
      end,

      refresh: lambda do |connection, refresh_token|
        {
          connection: connection,
          refresh_token: refresh_token
        }
      end,

      refresh_on: 401,

      detect_on: 404
    }
  },

  test: lambda do |connection, input|
    {
      connection: connection,
      input: input
    }
  end,

  actions: {
    echo_action: {
      execute: lambda do |connection, input, eis, eos, continue|
        {
          connection: connection,
          input: input,
          extended_input_schema: eis,
          extended_output_schema: eos,
          continue: continue
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
        [{
          object_definitions: object_definitions,
          connection: connection,
          config_fields: config_fields
        }]
      end,

      sample_output: lambda do |connection, input|
        {
          connection: connection,
          input: input
        }
      end
    },

    with_schema_action: {
      execute: lambda do |connection, input, eis, eos, continue|
        {
          connection: connection,
          input: input,
          input_schema: eis,
          output_schema: eos,
          continue: continue
        }
      end,

      input_fields: lambda do |_object_definitions, _connection, _config_fields|
        [
          { name: :input, type: :boolean }
        ]
      end,

      output_fields: lambda do |_object_definitions, _connection, _config_fields|
        [
          { name: :input, type: :object },
          { name: :connection, type: :object },
          { name: :input_schema, type: :object },
          { name: :output_schema, type: :object },
          { name: :continue, type: :object }
        ]
      end
    },

    with_error: {
      execute: lambda do
        error('Oops! Something went wrong')
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

      webhook_notification: lambda do |input, payload, eis, eos, headers, params, connection, wso|
        {
          input: input,
          payload: payload,
          extended_input_schema: eis,
          extended_output_schema: eos,
          headers: headers,
          params: params,
          connection: connection,
          webhook_subscribe_output: wso
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
    },

    with_schema_webhook_trigger: {
      webhook_notification: lambda do |input, payload, eis, eos, headers, params, connection, wso|
        {
          input: input,
          payload: payload,
          extended_input_schema: eis,
          extended_output_schema: eos,
          headers: headers,
          params: params,
          connection: connection,
          webhook_subscribe_output: wso
        }
      end,

      input_fields: lambda do |_object_definitions, _connection, _config_fields|
        [
          { name: :input, type: :boolean }
        ]
      end,

      output_fields: lambda do |_object_definitions, _connection, _config_fields|
        [
          { name: :input, type: :object },
          { name: :payload, type: :object },
          { name: :extended_input_schema, type: :object },
          { name: :extended_output_schema, type: :object },
          { name: :headers, type: :object },
          { name: :params, type: :object },
          { name: :connection, type: :object },
          { name: :webhook_subscribe_output, type: :object }
        ]
      end
    },

    with_schema_poll_trigger: {
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

      input_fields: lambda do |_object_definitions, _connection, _config_fields|
        [
          { name: :input, type: :boolean }
        ]
      end,

      output_fields: lambda do |_object_definitions, _connection, _config_fields|
        [
          { name: :connection, type: :object },
          { name: :input, type: :object },
          { name: :closure, type: :object }
        ]
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
        [
          {
            connection: connection,
            config_fields: config_fields
          }
        ]
      end
    }
  },

  streams: {
    echo_stream: lambda do |input, from, to, size|
      [{ input: input, from: from, to: to, size: size }, true]
    end
  }
}
