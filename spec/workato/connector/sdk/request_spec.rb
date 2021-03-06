# frozen_string_literal: true

module Workato::Connector::Sdk
  RSpec.describe Request, :vcr do
    subject(:execute!) { request.execute! }

    let(:request) { described_class.new(uri) }
    let(:uri) { 'https://jsonplaceholder.typicode.com/posts' }

    it { is_expected.to include('userId') }

    context 'when called implicitly' do
      it { expect(request.body['userId']).to be_present }
    end

    context 'with context' do
      let(:request_context) { OpenStruct.new(name: 'Mr. Contextual', retry_on_response: []) }
      let(:request) { described_class.new(uri, action: request_context).after_response { name } }

      it { is_expected.to eq('Mr. Contextual') }
    end

    context 'with query params' do
      let(:request) { described_class.new(uri).params(userId: '10') }

      it { is_expected.to include('"id": 100') }

      context 'when uri includes params' do
        let(:uri) { 'https://jsonplaceholder.typicode.com/posts?id=100' }

        it { is_expected.to include('"id": 100') }
      end
    end

    context 'with user and password' do
      let(:uri) { 'http://httpbin.org/basic-auth/user/password' }

      let(:request) { described_class.new(uri).user('user').password('password').format_json }

      it { is_expected.to include('authenticated' => true) }

      context 'when passed within authorize block' do
        let(:request) do
          described_class.new(uri, connection: connection, settings: settings.with_indifferent_access).format_json
        end
        let(:settings) { { user: 'user', password: 'password' } }
        let(:connection) do
          Connection.new(
            connection: {
              authorization: {
                apply: lambda { |connection|
                  user(connection[:user])
                  password(connection[:password])
                }
              }
            }
          )
        end

        it { is_expected.to include('authenticated' => true) }
      end
    end

    context 'with base_uri' do
      let(:uri) { '/posts' }
      let(:base_uri) { ->(connection) { "https://#{connection[:host]}" } }
      let(:connection) { Connection.new(connection: { base_uri: base_uri }) }
      let(:settings) { { host: 'jsonplaceholder.typicode.com' } }
      let(:request) { described_class.new(uri, connection: connection, settings: settings.with_indifferent_access) }

      it { is_expected.to include('userId') }
    end

    context 'with after_response' do
      let(:request) do
        described_class.new(uri).after_response do |code, response, headers|
          [code, response, headers]
        end
      end

      it { is_expected.to match_array([200, a_kind_of(String), a_kind_of(Hash)]) }
    end

    context 'with after_error_response' do
      let(:action) { Action.new(action: {}) }
      let(:request) do
        described_class.new(uri, action: action).after_error_response(500, 404) do |code, response, headers|
          [code, response, headers]
        end
      end
      let(:uri) { 'https://reqbin.com/mushrooms' }

      it { is_expected.to match_array([404, a_kind_of(String), a_kind_of(Hash)]) }

      context 'when error raised inside handler' do
        let(:request) do
          described_class.new(uri, action: action).after_error_response(500, 404) { error('Ooops') }
        end

        it { expect { subject }.to raise_error('Ooops') }
      end
    end

    context 'JSON' do
      let(:request) { described_class.new(uri).format_json }

      it { expect(execute!.size).to eq(100) }

      context 'when POST' do
        let(:request) { described_class.new(uri, method: 'POST').payload(payload).format_json }
        let(:payload) { { title: 'foo', body: 'bar', userId: 1 } }

        it { expect(execute!).to include('id' => 101) }

        context 'when array payload' do
          let(:uri) { 'https://httpbin.org/post' }
          let(:payload) { [1, 2, 3] }

          it { expect(execute!).to include('json' => [1, 2, 3]) }
        end
      end
    end

    context 'RAW' do
      let(:request) { described_class.new(uri, method: 'POST').format_json.request_body(payload) }
      let(:uri) { 'https://httpbin.org/post' }
      let(:payload) { 'custom body' }

      it { expect(execute!).to include('data' => 'custom body') }

      context 'when object payload' do
        let(:payload) { { a: :b } }

        it { expect(execute!).to include('form' => { 'a' => 'b' }) }
      end
    end

    context 'XML' do
      let(:request) { described_class.new(uri).format_xml('Response') }
      let(:uri) { 'https://reqbin.com/echo/get/xml' }
      let(:expected_response) do
        {
          'Response' => [
            {
              'ResponseCode' => [{ 'content!' => '0' }],
              'ResponseMessage' => [{ 'content!' => 'Success' }]
            }
          ]
        }
      end

      it { is_expected.to eq(expected_response) }

      context 'when POST' do
        let(:request) { described_class.new(uri, method: 'POST').format_xml('Request').payload(payload) }
        let(:uri) { 'https://reqbin.com/echo/post/xml' }
        let(:payload) { { 'Login' => 'login', 'Password' => 'password' } }

        it { is_expected.to eq(expected_response) }
      end
    end

    context 'application/x-www-form-urlencoded' do
      let(:request) do
        described_class
          .new(uri, method: 'POST')
          .response_format_json
          .request_format_www_form_urlencoded
          .payload(payload)
      end
      let(:uri) { 'http://httpbin.org/anything' }
      let(:payload) { { title: 'foo', body: 'bar', userId: 1 } }

      it { is_expected.to include('form' => { 'body' => 'bar', 'title' => 'foo', 'userId' => '1' }) }
    end

    context 'with case_sensitive_headers' do
      let(:request) do
        described_class.new(uri)
                       .request_format_json
                       .response_format_raw
                       .headers(headers)
                       .case_sensitive_headers(case_sensitive_headers)
      end
      let(:uri) { 'http://lvh.me:9876/' } # run nc -l 9876
      let(:headers) do
        {
          'x-hEaDer-1': 'x-hEaDer-1',
          'x_hEaDer-2' => 'x_hEaDer-2'
        }
      end
      let(:case_sensitive_headers) do
        {
          'x-hEaDer-3': 'x-hEaDer-3',
          'x_hEaDer-4' => 'x-hEaDer-4'
        }
      end
      let(:expected_headers) do
        "X-Header-1: x-hEaDer-1\n" \
        "X_header-2: x_hEaDer-2\n" \
        "x-hEaDer-3: x-hEaDer-3\n" \
        'x_hEaDer-4: x-hEaDer-4'
      end

      it { is_expected.to eq(expected_headers) }
    end

    context 'with digest_auth' do
      # rubocop:disable Lint/ConstantDefinitionInBlock
      module MockDigestMD5
        def hexdigest(str)
          if str == "1456185600:#{$$}:42" # rubocop:disable Style/SpecialGlobalVars
            return '4e9a1b9fd88aa52b4a8a0f0d3cf09b54'
          end

          super(str)
        end
      end
      # rubocop:enable Lint/ConstantDefinitionInBlock

      ::Digest::MD5.extend(MockDigestMD5)

      let(:request) { described_class.new(uri).user('user').password('password').digest_auth.format_json }
      let(:uri) { 'http://httpbin.org/digest-auth/auth/user/password' }

      around(:each) do |example|
        ::Timecop.freeze('2016-02-23T00:00:00Z'.to_time) { example.run }
      end

      before(:each) do
        allow(SecureRandom).to receive(:random_number).and_return(42)
      end

      it { is_expected.to include('authenticated' => true) }
    end

    context 'authorizations' do
      let(:request) do
        described_class.new(
          uri,
          connection: connection,
          settings: settings.with_indifferent_access,
          action: action
        ).format_json
      end
      let(:connection) { Connection.new(connection: { authorization: authorization }) }
      let(:settings) { { user: 'user', password: 'password' } }
      let(:action) { Action.new(action: {}) }

      context 'with user and password' do
        let(:uri) { 'http://httpbin.org/basic-auth/user/password' }
        let(:authorization) do
          {
            apply: lambda { |connection|
              user(connection[:user])
              password(connection[:password])
            }
          }
        end

        it { is_expected.to include('authenticated' => true) }
      end

      context 'with acquire' do
        let(:uri) { 'http://httpbin.org/basic-auth/user/password' }
        let(:action) { Action.new(action: {}, connection: connection) }
        let(:authorization) do
          {
            apply: lambda { |connection|
              user(connection[:user])
              password(connection[:password])
            },
            acquire: lambda { |_connection|
              post('http://httpbin.org/anything').payload(user: 'user', password: 'password')['json']
            }
          }
        end

        it { is_expected.to include('authenticated' => true) }
      end

      context 'with refresh' do
        let(:uri) { 'http://httpbin.org/basic-auth/user/password' }
        let(:action) { Action.new(action: {}, connection: connection) }
        let(:settings) { { user: 'user', access_token: 'expired', refresh_token: 'password' } }
        let(:authorization) do
          {
            type: :oauth2,
            apply: lambda { |connection|
              user(connection[:user])
              password(connection[:access_token])
            },
            refresh: lambda { |_connection, refresh_token|
              response = post('http://httpbin.org/anything').payload(
                access_token: refresh_token,
                refresh_token: refresh_token.reverse
              )
              response['json']
            }
          }
        end

        it { is_expected.to include('authenticated' => true) }
      end
    end

    context 'multipart/form-data', vcr: { match_requests_on: %i[uri multipart_body] } do
      let(:request) do
        described_class
          .new(uri, method: 'POST')
          .response_format_json
          .request_format_multipart_form
          .payload(payload)
      end
      let(:uri) { 'http://httpbin.org/anything' }
      let(:payload) { { file_part: ['lorem ipsum', 'text/ascii', 'lorem.txt'] } }

      it { is_expected.to include('files' => { 'file_part' => 'lorem ipsum' }) }
    end

    context 'with tls_client_cert' do
      # see spec/examples/custom_ssl/connector_spec.rb
    end
  end
end
