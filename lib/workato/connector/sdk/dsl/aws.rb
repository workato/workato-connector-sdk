# typed: false
# frozen_string_literal: true

require 'aws-sigv4'
require 'workato/utilities/xml'

module Workato
  module Connector
    module Sdk
      module Dsl
        module AWS
          TEMP_CREDENTIALS_REFRESH_TIMEOUT = 60 # seconds
          private_constant :TEMP_CREDENTIALS_REFRESH_TIMEOUT

          DUMMY_AWS_IAM_EXTERNAL_ID = 'dummy-aws-iam-external-id'
          private_constant :DUMMY_AWS_IAM_EXTERNAL_ID

          DUMMY_AWS_WORKATO_ACCOUNT_ID = 'dummy-aws-workato-account-id'
          private_constant :DUMMY_AWS_WORKATO_ACCOUNT_ID

          AMAZON_ROLE_CLIENT_ID = ENV.fetch('AMAZON_ROLE_CLIENT_ID', nil)
          private_constant :AMAZON_ROLE_CLIENT_ID

          AMAZON_ROLE_CLIENT_KEY = ENV.fetch('AMAZON_ROLE_CLIENT_KEY', nil)
          private_constant :AMAZON_ROLE_CLIENT_KEY

          AMAZON_ROLE_CLIENT_SECRET = ENV.fetch('AMAZON_ROLE_CLIENT_SECRET', nil)
          private_constant :AMAZON_ROLE_CLIENT_SECRET

          WWW_FORM_CONTENT_TYPE = 'application/x-www-form-urlencoded; charset=utf-8'
          private_constant :WWW_FORM_CONTENT_TYPE

          def aws
            @aws ||= Private.new(connection: connection)
          end

          class Private
            def initialize(connection:)
              @connection = connection
            end

            def generate_signature(connection:,
                                   service:,
                                   region:,
                                   host: "#{service}.#{region}.amazonaws.com",
                                   path: '/',
                                   method: 'GET',
                                   params: {},
                                   headers: {},
                                   payload: '')
              credentials = if connection[:aws_assume_role].present?
                              role_based_auth(settings: connection)
                            else
                              {
                                access_key_id: connection[:aws_api_key],
                                secret_access_key: connection[:aws_secret_key]
                              }
                            end

              url, headers = create_signature(
                credentials: credentials,
                service: service,
                host: host,
                region: region,
                method: method,
                path: path,
                params: params,
                headers: Utilities::HashWithIndifferentAccess.wrap(headers),
                payload: payload
              )

              {
                url: url,
                headers: headers
              }.with_indifferent_access
            end

            def iam_external_id
              @connection.settings[:aws_external_id] || DUMMY_AWS_IAM_EXTERNAL_ID
            end

            def workato_account_id
              @connection.settings[:aws_workato_account_id] || AMAZON_ROLE_CLIENT_ID || DUMMY_AWS_WORKATO_ACCOUNT_ID
            end

            private

            def role_based_auth(settings:)
              temp_credentials = settings[:temp_credentials] || @connection.settings[:temp_credentials] || {}

              # Refresh temp token that will expire within 60 seconds.
              expiration = temp_credentials[:expiration]&.to_time(:utc)
              if !expiration || expiration <= TEMP_CREDENTIALS_REFRESH_TIMEOUT.seconds.from_now
                @connection.update_settings!('Refresh AWS temporary credentials') do
                  { temp_credentials: refresh_temp_credentials(settings) }
                end
                temp_credentials = @connection.settings[:temp_credentials]
              end
              {
                access_key_id: temp_credentials[:api_key],
                secret_access_key: temp_credentials[:secret_key],
                session_token: temp_credentials[:session_token]
              }
            end

            def refresh_temp_credentials(settings)
              aws_external_id = settings[:aws_external_id] || iam_external_id
              sts_credentials = {
                access_key_id: amazon_role_client_key(settings),
                secret_access_key: amazon_role_client_secret(settings)
              }

              sts_params = {
                'Version' => '2011-06-15',
                'Action' => 'AssumeRole',
                'RoleSessionName' => 'workato',
                'RoleArn' => settings[:aws_assume_role],
                'ExternalId' => aws_external_id.presence
              }.compact

              sts_auth_url, sts_auth_headers = create_signature(
                credentials: sts_credentials,
                params: sts_params,
                service: 'sts',
                host: 'sts.amazonaws.com',
                region: 'us-east-1',
                headers: {
                  'Accept' => 'application/xml',
                  'Content-Type' => WWW_FORM_CONTENT_TYPE
                }
              )

              request_temp_credentials(url: sts_auth_url, headers: sts_auth_headers)
            rescue StandardError => e
              raise e if aws_external_id.blank?

              aws_external_id = nil
              retry
            end

            def request_temp_credentials(url:, headers:)
              response = RestClient::Request.execute(
                url: url,
                headers: headers,
                method: :get
              )
              response = Workato::Utilities::Xml.parse_xml_to_hash(response.body)

              temp_credentials = response.dig('AssumeRoleResponse', 0, 'AssumeRoleResult', 0, 'Credentials', 0)
              {
                session_token: temp_credentials.dig('SessionToken', 0, 'content!'),
                api_key: temp_credentials.dig('AccessKeyId', 0, 'content!'),
                secret_key: temp_credentials.dig('SecretAccessKey', 0, 'content!'),
                expiration: temp_credentials.dig('Expiration', 0, 'content!')
              }
            end

            def create_signature(credentials:,
                                 service:,
                                 host:,
                                 region:,
                                 path: '/',
                                 method: 'GET',
                                 params: {},
                                 headers: {},
                                 payload: '')
              url = URI::HTTPS.build(host: host, path: path, query: params.presence.to_param&.gsub('+', '%20')).to_s
              signer_options = {
                service: service,
                region: region,
                access_key_id: amazon_role_client_key(credentials),
                secret_access_key: amazon_role_client_secret(credentials),
                session_token: credentials[:session_token]
              }

              apply_service_specific_options(service, headers, signer_options, payload)

              signer = Aws::Sigv4::Signer.new(signer_options)
              signature = signer.sign_request(http_method: method, url: url, headers: headers, body: payload)

              headers_with_sig = merge_headers_with_sig_headers(headers, signature.headers)
              headers_with_sig = headers_with_sig.transform_keys { |key| key.gsub(/\b[a-z]/, &:upcase) }
              [url, headers_with_sig]
            end

            def apply_service_specific_options(service, headers, signer_options, payload)
              accept_headers = headers.key?('Accept') || headers.key?('accept')
              content_type = headers.key?('content-type') || headers.key?('Content-Type')

              case service
              when 'ec2'
                signer_options[:apply_checksum_header] = false

                headers.except!('Accept', 'Content-Type')
              when 's3'
                signer_options[:uri_escape_path] = false

                headers['Accept'] = 'application/xml' unless accept_headers
                headers['Content-Type'] = WWW_FORM_CONTENT_TYPE unless content_type
                headers['X-Amz-Content-SHA256'] = 'UNSIGNED-PAYLOAD' if payload.blank?
              when 'monitoring'
                signer_options[:apply_checksum_header] = false

                headers['Accept'] = 'application/json' unless accept_headers
                headers['Content-Type'] = WWW_FORM_CONTENT_TYPE unless content_type
              when 'lambda'
                signer_options[:apply_checksum_header] = false

                headers['Content-Type'] = WWW_FORM_CONTENT_TYPE unless content_type
              end
            end

            def merge_headers_with_sig_headers(headers, sig_headers)
              headers_keys = headers.transform_keys { |key| key.to_s.downcase }
              sig_headers_to_merge = sig_headers.reject { |key| headers_keys.include?(key.downcase) }
              headers.merge(sig_headers_to_merge)
            end

            def amazon_role_client_key(settings)
              settings[:access_key_id] || @connection.settings[:access_key_id] || AMAZON_ROLE_CLIENT_KEY
            end

            def amazon_role_client_secret(settings)
              settings[:secret_access_key] || @connection.settings[:access_key_id] || AMAZON_ROLE_CLIENT_SECRET
            end
          end

          private_constant :Private
        end
      end
    end
  end
end
