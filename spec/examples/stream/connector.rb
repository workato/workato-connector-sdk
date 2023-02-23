# typed: false
# frozen_string_literal: true

{
  title: 'Stream',

  connection: {
    authorization: {
      type: 'none'
    }
  },

  streams: {
    global_stream: lambda do |input, first_byte, _last_byte, size|
      upper_size = (input['file_size'] || 100_000).to_i
      if first_byte >= upper_size
        ['', true]
      else
        ['A' * size, false]
      end
    end
  },

  methods: {
    with_stream_out: lambda do |input|
      workato.stream.out('action_stream', input)
    end,
    with_stream_in: lambda do |stream, from: nil, frame_size: nil|
      stream_data = ''
      stream_count = 0
      workato.stream.in(stream, from: from, frame_size: frame_size) do |chunk, _start_byte, _end_byte, _eof|
        stream_data += chunk
        stream_count += 1
      end
      [stream_data, stream_count]
    end,
    with_stream_in_out: lambda do |input|
      stream = call(:with_stream_out, input)
      call(:with_stream_in, stream)
    end
  },

  actions: {
    test_action: {
      input_fields: lambda do
        [
          { name: 'file_size', type: 'number' },
          { name: 'mock_simple_stream', type: 'stream' },
          { name: 'mock_advanced_stream', type: 'stream' },
          { name: 'mock_self_stream', type: 'stream' },
          { name: 'static_stream' },
          { name: 'string' }
        ]
      end,

      execute: lambda do |_, input|
        global_stream = workato.stream.out('global_stream', input)
        global_stream_data = ''
        global_stream_count = 0
        workato.stream.in(global_stream, frame_size: input[:frame_size]) do |chunk, _start_byte, _end_byte, _eof|
          global_stream_data += chunk
          global_stream_count += 1
        end
        global_stream_data_size = global_stream_data.size.to_s(:human_size)

        action_stream = workato.stream.out('action_stream', input)
        action_stream_data = ''
        action_stream_count = 0
        workato.stream.in(action_stream) do |chunk, _start_byte, _end_byte, _eof|
          action_stream_data += chunk
          action_stream_count += 1
        end
        action_stream_data_size = action_stream_data.size.to_s(:human_size)

        method_stream_data, method_stream_count = call(:with_stream_in_out, input)
        method_stream_data_size = method_stream_data.size.to_s(:human_size)

        mock_simple_stream_data, mock_simple_stream_count = call(:with_stream_in, input[:mock_simple_stream], from: 4)
        mock_simple_stream_data_size = mock_simple_stream_data.size.to_s(:human_size)
        mock_simple_stream_summary = "Downloaded #{mock_simple_stream_data_size} in #{mock_simple_stream_count} batches"

        mock_adv_stream_data, mock_adv_stream_count = call(:with_stream_in, input[:mock_advanced_stream])
        mock_adv_stream_data_size = mock_adv_stream_data.size.to_s(:human_size)
        mock_adv_stream_summary = "Downloaded #{mock_adv_stream_data_size} in #{mock_adv_stream_count} batches"

        mock_self_stream_data, mock_self_stream_count = call(:with_stream_in, input[:mock_self_stream])
        mock_self_stream_data_size = mock_self_stream_data.size.to_s(:human_size)
        mock_self_stream_summary = "Downloaded #{mock_self_stream_data_size} in #{mock_self_stream_count} batches"

        static_stream_data, static_stream_count = call(:with_stream_in, input[:static_stream], from: 5, frame_size: 3)
        static_stream_data_size = static_stream_data.size.to_s(:human_size)

        string_data, string_data_count = call(:with_stream_in, input[:string], from: 6, frame_size: 2)
        string_data_size = string_data.size.to_s(:human_size)

        {
          global_stream: global_stream,
          global_stream_summary: "Downloaded #{global_stream_data_size} in #{global_stream_count} batches",
          action_stream: action_stream,
          action_stream_summary: "Downloaded #{action_stream_data_size} in #{action_stream_count} batches",
          methods_with_stream: call(:with_stream_out, input),
          methods_with_stream_summary: "Downloaded #{method_stream_data_size} in #{method_stream_count} batches",
          mock_simple_stream_summary: mock_simple_stream_summary,
          static_stream_summary: "Downloaded #{static_stream_data_size} in #{static_stream_count} batches",
          string_summary: "Downloaded #{string_data_size} in #{string_data_count} batches",
          mock_advanced_stream_summary: mock_adv_stream_summary,
          mock_self_stream_summary: mock_self_stream_summary
        }
      end,

      streams: {
        action_stream: lambda do |input, _first_byte, last_byte, size|
          upper_size = (input['file_size'] || 100_000).to_i
          ['A' * size, last_byte >= upper_size]
        end
      },

      output_fields: lambda do
        [
          { name: 'global_stream' },
          { name: 'action_stream' },
          { name: 'methods_with_stream' },
          { name: 'action_stream_summary' },
          { name: 'methods_with_stream_summary' },
          { name: 'static_stream_summary' },
          { name: 'string_summary' },
          { name: 'mock_advanced_stream' },
          { name: 'mock_simple_stream_summary' }
        ]
      end
    },

    with_reinvoke_after: {
      execute: lambda do |_connection, input, _input_schema, _output_schema, closure|
        stream = workato.stream.out('global_stream', input)

        data = closure[:data] || ''
        count = closure[:count] || 0
        from = closure[:from] || 0

        workato.stream.in(stream, from: from) do |chunk, _start_byte, _end_byte, eof, next_from|
          data += chunk
          count += 1
          reinvoke_after(seconds: 0.1, continue: { data: data, count: count, from: next_from }) unless eof
        end

        {
          summary: "Downloaded #{data.size.to_s(:human_size)} in #{count} batches"
        }
      end
    }
  }
}
