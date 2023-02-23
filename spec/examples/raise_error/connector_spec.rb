# typed: false
# frozen_string_literal: true

RSpec.describe 'raise_error' do
  let(:connector) do
    Workato::Connector::Sdk::Connector.from_file(connector_file_path)
  end

  let(:connector_file_path) { './spec/examples/raise_error/connector.rb' }

  it 'raises error' do
    expect { connector.actions.action_with_error.execute }.to raise_error('undefined method `+\' for nil:NilClass')
  end

  context 'when raising explicitly' do
    it 'raises error' do
      expect { connector.actions.action_with_own_raise.execute }
        .to raise_error('custom test error')
    end
  end

  context 'when error in after_response' do
    before do
      stub_request(:get, 'http://localhost/test_for_raise_in_after_response')
        .to_return(body: 'foobar', status: 200)
    end

    it 'raises error with naturally expected stacktrace' do
      expect { connector.actions.action_with_own_raise_in_after_response.execute }.to raise_error do |err|
        expect(err.message).to eq('error from after_response')

        sdk_code_backtrace = Array.wrap(err.backtrace).select { |s| s.start_with?(connector_file_path) }
        expect(sdk_code_backtrace).to contain_exactly(
          "./spec/examples/raise_error/connector.rb:26:in `block in from_file'",
          "./spec/examples/raise_error/connector.rb:27:in `block (2 levels) in from_file'"
        )
      end
    end
  end
end
