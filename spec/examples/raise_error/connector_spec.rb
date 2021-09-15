# frozen_string_literal: true

RSpec.describe 'raise_error' do
  let(:connector) do
    Workato::Connector::Sdk::Connector.from_file('./spec/examples/raise_error/connector.rb')
  end

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
    before(:each) do
      stub_request(:get, 'http://localhost/test_for_raise_in_after_response')
        .to_return(body: 'foobar', status: 200)
    end

    it 'raises error' do
      expect { connector.actions.action_with_own_raise_in_after_response.execute }
        .to raise_error('error from after_response')
    end
  end
end
