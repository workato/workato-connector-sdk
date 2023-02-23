# typed: false
# frozen_string_literal: true

RSpec.describe 'recursive requests' do
  let(:connector) do
    Workato::Connector::Sdk::Connector.from_file('./spec/examples/recursive_requests/connector.rb')
  end

  it 'makes recursive after_response requests' do
    stub_request(:get, 'http://localhost/test_request_one')
      .to_return(body: 'one', status: 200)
    stub_request(:get, 'http://localhost/test_request_two')
      .to_return(body: 'two', status: 200)
    stub_request(:get, 'http://localhost/test_request_three')
      .to_return(body: JSON.dump(response: 'three'), status: 200)

    output = connector.actions.action_with_chained_requests.execute

    expect(output).to include('response' => 'three')
  end
end
