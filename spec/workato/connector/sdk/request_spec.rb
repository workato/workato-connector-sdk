# typed: false
# frozen_string_literal: true

module Workato::Connector::Sdk
  RSpec.describe Request, :vcr do
    subject(:response) { request.response! }

    let(:request) { described_class.new(uri) }
    let(:uri) { 'https://jsonplaceholder.typicode.com/posts' }

    it { is_expected.to include('userId') }

    context 'when called implicitly' do
      it { expect(request.body['userId']).to be_present }
      it { expect(request.try(:body).try(:[], 'userId')).to be_present }
    end

    context 'with context' do
      let(:request_context) { double(name: 'Mr. Contextual', retry_on_response: []) } # rubocop:disable RSpec/VerifiedDoubles
      let(:request) { described_class.new(uri, action: request_context).after_response { name } }

      it { is_expected.to eq('Mr. Contextual') }
    end

    context 'with query params' do
      let(:uri) { 'https://httpbin.org/anything' }
      let(:request) { described_class.new(uri).params(params).format_json }
      let(:params) { { userId: '10' } }

      it { is_expected.to include('args' => { 'userId' => '10' }) }

      context 'when uri includes params' do
        let(:uri) { 'https://httpbin.org/anything?id=100' }

        it { is_expected.to include('args' => { 'userId' => '10', 'id' => '100' }) }
      end

      context 'when params is string' do
        let(:params) { 'userId=10' }

        it { is_expected.to include('args' => { 'userId' => '10' }) }
      end
    end

    context 'with user and password' do
      let(:uri) { 'http://httpbin.org/basic-auth/user/password' }

      let(:request) { described_class.new(uri).user('user').password('password').format_json }

      it { is_expected.to include('authenticated' => true) }

      context 'when passed within authorize block' do
        let(:request) do
          described_class.new(uri, connection: connection).format_json
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
            },
            settings: settings
          )
        end

        it { is_expected.to include('authenticated' => true) }
      end
    end

    context 'with base_uri' do
      let(:uri) { '/posts' }
      let(:base_uri) { ->(connection) { "https://#{connection[:host]}" } }
      let(:connection) { Connection.new(connection: { base_uri: base_uri }, settings: settings) }
      let(:settings) { { host: 'jsonplaceholder.typicode.com' } }
      let(:request) { described_class.new(uri, connection: connection) }

      it { is_expected.to include('userId') }
    end

    context 'with after_response' do
      let(:request) do
        described_class.new(uri).after_response do |code, response, headers|
          [code, response, headers]
        end
      end

      it { is_expected.to contain_exactly(200, a_kind_of(String), a_kind_of(Hash)) }
    end

    context 'with after_error_response' do
      let(:action) { Action.new(action: {}) }
      let(:request) do
        described_class.new(uri, action: action).after_error_response(500, 404) do |code, response, headers|
          [code, response, headers]
        end
      end
      let(:uri) { 'https://reqbin.com/mushrooms' }

      it { is_expected.to contain_exactly(404, a_kind_of(String), a_kind_of(Hash)) }

      context 'when error raised inside handler' do
        let(:request) do
          described_class.new(uri, action: action).after_error_response(500, 404) { error('Ooops') }
        end

        it { expect { response }.to raise_error('Ooops') }
      end
    end

    context 'with JSON' do
      let(:request) { described_class.new(uri).format_json }

      it { expect(response.size).to eq(100) }

      context 'when POST' do
        let(:request) { described_class.new(uri, method: 'POST').payload(payload).format_json }
        let(:payload) { { title: 'foo', body: 'bar', userId: 1 } }

        it { expect(response).to include('id' => 101) }

        context 'when array payload' do
          let(:uri) { 'https://httpbin.org/post' }
          let(:payload) { [1, 2, 3] }

          it { expect(response).to include('json' => [1, 2, 3]) }
        end
      end

      context 'when request payload format error' do
        let(:request) { described_class.new(uri, method: 'POST').payload(payload).format_json }
        let(:payload) { { title: "\xE0" } }

        it { expect { response }.to raise_error(JSONRequestFormatError) }
      end

      context 'when response payload format error' do
        let(:uri) { 'https://httpbin.org/html' }

        it { expect { response }.to raise_error(JSONResponseFormatError, /unexpected token at/) }
      end
    end

    context 'with RAW' do
      let(:request) { described_class.new(uri, method: 'POST').format_json.request_body(payload) }
      let(:uri) { 'https://httpbin.org/post' }
      let(:payload) { 'custom body' }

      it { expect(response).to include('data' => 'custom body') }

      context 'when object payload' do
        let(:payload) { { a: :b } }

        it { expect(response).to include('form' => { 'a' => 'b' }) }
      end
    end

    context 'with XML' do
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

    context 'with application/x-www-form-urlencoded' do
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
      let(:uri) { 'http://lvh.me:9876/' } # run nc -l -p 9876
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
      # rubocop:disable RSpec/LeakyConstantDeclaration
      module MockDigestMD5
        def hexdigest(str)
          if str == "1456185600:#{$$}:42" # rubocop:disable Style/SpecialGlobalVars
            return '4e9a1b9fd88aa52b4a8a0f0d3cf09b54'
          end

          super(str)
        end
      end
      # rubocop:enable Lint/ConstantDefinitionInBlock
      # rubocop:enable RSpec/LeakyConstantDeclaration

      ::Digest::MD5.extend(MockDigestMD5)

      let(:request) { described_class.new(uri).user('user').password('password').digest_auth.format_json }
      let(:uri) { 'http://httpbin.org/digest-auth/auth/user/password' }

      around do |example|
        ::Timecop.freeze('2016-02-23T00:00:00Z'.to_time) { example.run }
      end

      before do
        allow(SecureRandom).to receive(:random_number).and_return(42)
      end

      it { is_expected.to include('authenticated' => true) }
    end

    context 'with authorizations' do
      let(:uri) { 'http://httpbin.org/basic-auth/user/password' }
      let(:request) { described_class.new(uri, connection: connection).format_json }
      let(:connection) { Connection.new(connection: { authorization: authorization }, settings: settings) }
      let(:settings) { {} }

      context 'with user and password' do
        let(:settings) { { user: 'user', password: 'password' } }
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

        context 'when random error' do
          before do
            stub_request(:get, 'http://httpbin.org/basic-auth/user/password').to_raise(SocketError.new('bad connect'))
          end

          it 'does not trigger refresh token' do
            allow(connection).to receive(:update_settings!).and_call_original

            expect { response }.to raise_error(SocketError, 'bad connect')
            expect(connection).not_to have_received(:update_settings!)
          end
        end
      end

      context 'with oauth2 and refresh' do
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

        context 'when random error' do
          before do
            stub_request(:get, 'http://httpbin.org/basic-auth/user/password').to_raise(SocketError.new('bad connect'))
          end

          it 'does not trigger refresh token' do
            allow(connection).to receive(:update_settings!).and_call_original

            expect { response }.to raise_error(SocketError, 'bad connect')
            expect(connection).not_to have_received(:update_settings!)
          end
        end
      end

      context 'when unauthorized response' do
        let(:authorization) do
          {
            apply: lambda { |connection|
              user(connection[:user])
              password(connection[:password])
            }
          }
        end

        it 'does not trigger refresh token' do
          allow(connection).to receive(:update_settings!).and_call_original

          expect { response }.to raise_error(RequestError, '401 Unauthorized')
          expect(connection).not_to have_received(:update_settings!)
        end
      end
    end

    context 'with multipart/form-data', vcr: { match_requests_on: %i[uri multipart_body] } do
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

    context 'with tls_client_cert' do # rubocop:disable RSpec/EmptyExampleGroup
      # see spec/examples/custom_ssl/connector_spec.rb
    end
  end
end
