# typed: false
# frozen_string_literal: true

RSpec.describe 'stream', :vcr do
  let(:connector) { Workato::Connector::Sdk::Connector.from_file('./spec/examples/stream/connector.rb') }

  before do
    stub_const('Workato::Connector::Sdk::Stream::Reader::DEFAULT_FRAME_SIZE', 5.kilobytes)
  end

  describe 'streams' do
    describe 'global_stream' do
      subject(:output) { connector.streams.global_stream }

      it 'reads stream chunk' do
        expect(output).to contain_exactly(be_a(String), false)
      end
    end

    describe 'global_stream!' do
      subject(:output) { connector.streams.global_stream! }

      it 'reads stream till eof' do
        expect(output).to be_a(String)
      end
    end
  end

  describe 'actions' do
    describe 'test_action' do
      subject(:action) { connector.actions.test_action }

      let(:input) do
        {
          file_size: 20.kilobytes,
          frame_size: frame_size,
          # self stream mock can be used in input JSON for workato exec CLI
          mock_self_stream: JSON.parse(
            {
              __stream__: true,
              name: 'global_stream',
              input: {
                file_size: 11.kilobytes
              }
            }.to_json
          ),
          # simple stream mock can be used in input JSON for workato exec CLI
          mock_simple_stream: JSON.parse(
            {
              __stream__: true,
              chunks: {
                0 => 'abcd',
                4 => 'efgh',
                8 => 'ijkl',
                12 => 'mn'
              }
            }.to_json
          ),
          mock_advanced_stream: {
            __stream__: true,
            name: 'mock_advanced_stream',
            input: {
              file_size: 9.kilobytes
            },
            settings: {
              # optional
              # A connection settings for stream mock application
              # if the mock makes authorized requests to external apps
              # Also can use Workato::Connector::Sdk::Settings.from_file
            },
            connection: {
              # optional
              # A connection definition for stream source applications
              # if the mock makes authorized requests to external apps
              # It supports the same blocks as connector's connection definition
              authorization: {
                type: 'none'
              }
            },
            chunks: lambda do |input, _first_byte, last_byte, size|
              ['A' * size, last_byte >= input['file_size'].to_i]
            end
          },
          static_stream: {
            data: '1234567890',
            oef: true
          },
          string: 'qwertyuiop[]'
        }
      end
      let(:frame_size) { nil }

      let(:expected_output) do
        {
          global_stream: a_kind_of(Workato::Connector::Sdk::Stream::Proxy),
          global_stream_summary: 'Downloaded 20 KB in 5 batches',
          action_stream: a_kind_of(Workato::Connector::Sdk::Stream::Proxy),
          action_stream_summary: 'Downloaded 25 KB in 5 batches',
          methods_with_stream: a_kind_of(Workato::Connector::Sdk::Stream::Proxy),
          methods_with_stream_summary: 'Downloaded 25 KB in 5 batches',
          static_stream_summary: 'Downloaded 5 Bytes in 1 batches',
          mock_simple_stream_summary: 'Downloaded 10 Bytes in 3 batches',
          string_summary: 'Downloaded 6 Bytes in 1 batches',
          mock_advanced_stream_summary: 'Downloaded 10 KB in 2 batches',
          mock_self_stream_summary: 'Downloaded 15 KB in 4 batches'
        }
      end

      describe 'invoke' do
        subject(:output) { action.invoke(input) }

        it { is_expected.to include(expected_output) }
      end

      describe 'execute' do
        subject(:output) { action.execute(nil, input) }

        it { is_expected.to include(expected_output) }

        context 'with frame size' do
          let(:frame_size) { 30.kilobytes }

          let(:expected_output) do
            { global_stream_summary: 'Downloaded 30 KB in 2 batches' }
          end

          it { is_expected.to include(expected_output) }
        end
      end
    end

    describe 'with_reinvoke_after' do
      subject(:action) { connector.actions.with_reinvoke_after }

      describe 'execute' do
        subject(:output) { action.execute(nil, input) }

        let(:input) { { file_size: 20.kilobytes } }

        let(:expected_output) { { summary: 'Downloaded 20 KB in 5 batches' } }

        it { is_expected.to include(expected_output) }
      end
    end
  end

  describe 'methods.with_stream_in_out' do
    subject(:action) { connector.methods.with_stream_in_out(input) }

    let(:input) { { file_size: 11.kilobytes } }

    it { is_expected.to eq(['A' * 15.kilobytes, 3]) }
  end
end
