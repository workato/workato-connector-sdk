# typed: false
# frozen_string_literal: true

RSpec.describe 'custom_ssl' do
  let(:connector) { Workato::Connector::Sdk::Connector.from_file('./spec/examples/custom_ssl/connector.rb') }

  describe 'server TLS certificates' do
    subject(:output) { connector.actions.posts.execute(settings) }

    around do |example|
      start_https_localhost(example)
    end

    let(:settings) { {} }

    describe 'client not disabling TLS server certificate verification' do
      it 'does not trust server certificate without proper chain' do
        expect { output }.to raise_error(/certificate verify failed/)
      end
    end

    context 'when server custom CA certificate is provided' do
      let(:settings) do
        { custom_server_cert: File.read('spec/fixtures/pki/root_servers_ca/ca_cert.pem') }
      end

      it 'trusts server certificate with self-signed certificate' do
        expect(output['posts']).not_to be_empty
      end

      context 'when connect to servers not included in custom CA' do
        before do
          allow_any_instance_of(OpenSSL::X509::Store).to receive(:set_default_paths) do |instance|
            instance.add_file('spec/fixtures/pki/root_servers_ca/ca_cert.pem')
          end
        end

        let(:settings) do
          { custom_server_cert: File.read('spec/fixtures/pki/root_clients_ca/ca_cert.pem') }
        end

        it 'does not trust other servers' do
          expect { output }.to raise_error(/certificate verify failed/)
        end

        context 'when connections to other servers allowed' do
          it 'trusts server with common CA certificate' do
            output = connector.actions.posts_weak.execute(settings)

            expect(output['posts']).not_to be_empty
          end
        end
      end
    end
  end

  describe 'client TLS certificates' do
    subject(:output) { connector.actions.posts.execute(settings) }

    around do |example|
      start_https_localhost(
        example,
        webrick: {
          SSLVerifyClient: OpenSSL::SSL::VERIFY_FAIL_IF_NO_PEER_CERT | OpenSSL::SSL::VERIFY_PEER,
          SSLVerifyDepth: 3,
          SSLCertificateStore: (
            OpenSSL::X509::Store.new.tap do |store|
              store.add_cert(
                OpenSSL::X509::Certificate.new(
                  File.read('spec/fixtures/pki/root_clients_ca/ca_cert.pem')
                )
              )
            end
          )
        }
      )
    end

    let(:settings) do
      {
        client_cert: File.read('spec/fixtures/pki/test_client_cert.pem'),
        client_key: File.read('spec/fixtures/pki/test_client_key.pem'),
        custom_server_cert: File.read('spec/fixtures/pki/root_servers_ca/ca_cert.pem')
      }
    end

    describe 'client without intermediate' do
      it 'server should fail to trust client' do
        expect { output }.to raise_error(/tlsv1 alert unknown ca/)
      end
    end

    describe 'client with intermediate' do
      let(:settings) do
        {
          client_cert: File.read('spec/fixtures/pki/test_client_cert.pem'),
          client_key: File.read('spec/fixtures/pki/test_client_key.pem'),
          client_intermediate_cert: File.read('spec/fixtures/pki/intermediate_clients_ca/ca_cert.pem'),
          custom_server_cert: File.read('spec/fixtures/pki/root_servers_ca/ca_cert.pem')
        }
      end

      it 'server should trust client' do
        expect(output['posts']).not_to be_empty
      end
    end

    describe 'client with mis-formatted intermediate' do
      let(:settings) do
        {
          client_cert: File.read('spec/fixtures/pki/test_client_cert.pem'),
          client_key: File.read('spec/fixtures/pki/test_client_key.pem'),
          client_intermediate_cert: 'invalid',
          custom_server_cert: File.read('spec/fixtures/pki/root_clients_ca/ca_cert.pem')
        }
      end

      it 'fails with certificate error' do
        expect { output }.to raise_error(Workato::Connector::Sdk::RequestTLSCertificateFormatError)
      end
    end
  end

  private

  def start_https_localhost(example, additional_server_options = {})
    default_server_options = {
      ssl: {
        cert: File.read('spec/fixtures/pki/localhost_server_cert.pem'),
        key: File.read('spec/fixtures/pki/localhost_server_key.pem')
      },
      webrick: {
        SSLExtraChainCert: [
          OpenSSL::X509::Certificate.new(File.read('spec/fixtures/pki/intermediate_servers_ca/ca_cert.pem'))
        ]
      },
      json: true
    }
    replies = { '/posts' => [200, {}, { name: 'James', created_at: Time.zone.now }] }
    server_options = default_server_options.deep_merge(additional_server_options)

    StubServer.open(9123, replies, **server_options) do |server|
      server.wait
      example.run
    end
  end
end
