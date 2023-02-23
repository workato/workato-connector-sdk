# typed: false
# frozen_string_literal: true

RSpec.describe 'parallel_requests', :vcr do
  subject(:output) { connector.actions.test_action.execute({}, input) }

  let(:connector) do
    Workato::Connector::Sdk::Connector.from_file('./spec/examples/parallel_requests/connector.rb')
  end
  let(:input) { { urls: urls } }
  let(:urls) do
    [
      'http://localhost/a',
      'http://localhost/b',
      'http://localhost/unauthorized',
      'http://localhost/d?token=abcd'
    ]
  end

  before do
    stub_request(:get, 'http://localhost/a').to_return(body: 'a', status: 200)
    stub_request(:get, 'http://localhost/b').to_return(body: 'b', status: 200)
    stub_request(:get, 'http://localhost/422').to_return(body: 'error', status: 422)
    stub_request(:get, 'http://localhost/422?token=abcd').to_return(body: 'error', status: 422)
    stub_request(:get, 'http://localhost/json').to_return(body: '{"a": "A"}', status: 200)
    stub_request(:get, 'http://localhost/unauthorized').to_return(body: 'unauthorized', status: 401)
    stub_request(:get, 'http://localhost/unauthorized?token=abcd').to_return(body: 'c', status: 200)
    stub_request(:get, 'http://localhost/d?token=abcd').to_return(body: 'd', status: 200)
  end

  it 'makes requests' do
    expect(output).to eq(
      'result' => [
        true,
        %w[a b c d],
        [nil, nil, nil, nil]
      ]
    )
  end

  context 'with HTTP error' do
    let(:urls) do
      [
        'http://localhost/a',
        'http://localhost/422',
        'http://localhost/unauthorized',
        'http://localhost/d?token=abcd'
      ]
    end

    it 'makes requests' do
      expect(output).to eq(
        'result' => [
          false,
          ['a', nil, 'c', 'd'],
          [nil, '422 Unprocessable Entity', nil, nil]
        ]
      )
    end
  end

  context 'when JSON::ParserError error' do
    subject(:output) { connector.actions.test_action_with_json_parse_error.execute }

    it 'makes requests' do
      expect(output).to include(
        'result' => [
          false,
          [{ 'a' => 'A' }, nil],
          [nil, /unexpected token at 'a'/]
        ]
      )
    end
  end

  context 'when error' do
    subject(:output) { connector.actions.test_action_with_error.execute }

    it 'makes requests' do
      expect(output).to eq(
        'result' => [
          false,
          [{ 'a' => 'A' }, nil, 'b'],
          [nil, 'OOOPs! Something went wrong', nil]
        ]
      )
    end
  end
end
