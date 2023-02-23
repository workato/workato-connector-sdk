# typed: false
# frozen_string_literal: true

RSpec.describe 'custom_adapter_definition_with_backoff', :vcr do
  let(:connector) do
    Workato::Connector::Sdk::Connector.from_file('./spec/examples/custom_adapter_definition_with_backoff/connector.rb')
  end

  before do
    stub_const('Workato::Connector::Sdk::Action::RETRY_DELAY', 0.1)
  end

  it 'retries action' do
    output = connector.actions.custom_http.execute({}, { url: 'http://www.mocky.io/v2/5e1c138a3200006500228141' })
    expect(output[:results]['success']).to be_truthy
  end

  context 'when retry_on_response is array' do
    it 'retries action' do
      output = connector.actions.test_single_400_code_3_retry_get_method.execute
      expect(output[:results]['success']).to be_truthy
    end
  end

  context 'when retry_on_response is not defined' do
    it 'does not retry action and ignores other retry options' do
      expect { connector.actions.test_single_400_code_no_retry_get_method.execute }
        .to raise_error(Workato::Connector::Sdk::RequestError)
    end
  end

  context 'when retry_on_response does not includes error HTTP code' do
    it 'does not retry action' do
      expect { connector.actions.test_no_code_2_retry_get_method.execute }
        .to raise_error(Workato::Connector::Sdk::RequestError)
    end

    context 'when HTTR error code is default to retry' do
      it 'retries action' do
        output = connector.actions.test_default_code_3_retry_get_method.execute
        expect(output[:results]['success']).to be_truthy
      end
    end
  end

  context 'when retry attempts exhausted' do
    it 'raises action after max retries' do
      expect { connector.actions.test_double_408_code_2_retry_get_method.execute }
        .to raise_error(Workato::Connector::Sdk::RequestError)
    end
  end
end
