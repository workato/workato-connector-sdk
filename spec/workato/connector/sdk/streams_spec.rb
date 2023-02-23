# typed: false
# frozen_string_literal: true

module Workato::Connector::Sdk
  RSpec.describe Streams do
    subject(:streams) { described_class.new(streams: stream_definitions) }

    let(:stream_definitions) do
      {
        test_stream: lambda do
          data = 'A' * rand(2..9)
          [data, rand(100) > 50]
        end
      }
    end

    describe 'test_stream' do
      subject(:test_stream) { streams.test_stream }

      it { is_expected.to contain_exactly(/^A+$/, be_in([true, false])) }
    end

    describe 'test_stream!' do
      subject(:chunk) { streams.test_stream! }

      it { is_expected.to match(/^A+$/) }
    end
  end
end
