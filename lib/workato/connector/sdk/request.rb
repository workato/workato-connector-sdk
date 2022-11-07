# typed: false
# frozen_string_literal: true

require 'delegate'
require 'rest-client'
require 'json'
require 'gyoku'
require 'net/http'
require 'net/http/digest_auth'

require 'workato/utilities/encoding'
require 'workato/utilities/xml'
require_relative './block_invocation_refinements'

using Workato::Extension::HashWithIndifferentAccess

module Workato
  module Connector
    module Sdk
      class Request < SimpleDelegator
        extend T::Sig

        using BlockInvocationRefinements

        def initialize(uri, method: 'GET', connection: nil, action: nil)
          super(nil)
          @uri = uri
          @method = method
          @connection = connection
          @base_uri = connection&.base_uri(connection&.settings || {})
          @action = action
          @headers = {}
          @case_sensitive_headers = {}
          @render_request = ->(payload) { payload }
          @parse_response = ->(payload) { payload }
          @after_response = ->(_response_code, parsed_response, _response_headers) { parsed_response }
          @callstack_before_request = Array.wrap(Kernel.caller)
        end

        def method_missing(*args, &block)
          execute!.send(*args, &block)
        end

        def execute!
          __getobj__ || __setobj__(response)
        rescue RestClient::Exception => e
          if after_error_response_matches?(e)
            return apply_after_error_response(e)
          end

          Kernel.raise RequestError.new(
            response: e.response,
            message: e.message,
            method: current_verb,
            code: e.http_code
          )
        rescue StandardError => e
          error_backtrace = Array.wrap(e.backtrace)
          first_call_after_request_idx = error_backtrace.rindex { |s| s.start_with?(__FILE__) }
          error_backtrace_after_request = error_backtrace[0..first_call_after_request_idx]
          e.set_backtrace(error_backtrace_after_request + @callstack_before_request)
          Kernel.raise e
        end

        def headers(headers)
          @headers.merge!(headers)
          self
        end

        def case_sensitive_headers(headers)
          @case_sensitive_headers.merge!(headers)
          self
        end

        def params(params)
          if params.is_a?(Hash)
            @params ||= HashWithIndifferentAccess.new
            @params.merge!(params)
          else
            @params = params
          end
          self
        end

        def payload(payload = nil)
          case payload
          when Array
            @payload ||= []
            @payload += payload
          when NilClass
            # no-op
          else
            @payload ||= {}.with_indifferent_access
            @payload.merge!(payload)
          end
          yield(@payload) if Kernel.block_given?
          self
        end

        def user(usr)
          @user = usr
          self
        end

        def password(pwd)
          @password = pwd
          self
        end

        def digest_auth
          @digest_auth = true
          self
        end

        def follow_redirection
          @follow_redirection = true
          self
        end

        def ignore_redirection
          @follow_redirection = false
          self
        end

        def after_response(&after_response)
          @after_response = after_response
          self
        end

        def after_error_response(*matches, &after_error_response)
          @after_error_response_matches = matches
          @after_error_response = after_error_response
          self
        end

        def format_json
          request_format_json.response_format_json
        end

        def request_format_json
          @content_type_header = :json
          @render_request = lambda_with_error_wrap(JSONRequestFormatError) do |payload|
            ActiveSupport::JSON.encode(payload) if payload
          end
          self
        end

        def response_format_json
          @accept_header = :json
          @parse_response = lambda_with_error_wrap(JSONResponseFormatError) do |payload|
            ActiveSupport::JSON.decode(payload.presence || '{}')
          end
          self
        end

        def format_xml(root_element_name, namespaces = {}, **options)
          request_format_xml(root_element_name, namespaces).response_format_xml(**options)
        end

        def request_format_xml(root_element_name, namespaces = {})
          @content_type_header = :xml
          @render_request = lambda_with_error_wrap(XMLRequestFormatError) do |payload|
            next unless payload

            Gyoku.xml({ root_element_name => payload.merge(namespaces).deep_symbolize_keys }, key_converter: :none)
          end
          self
        end

        def response_format_xml(strip_response_namespaces: false)
          @accept_header = :xml
          @parse_response = lambda_with_error_wrap(XMLResponseFormatError) do |payload|
            Workato::Utilities::Xml.parse_xml_to_hash(payload, strip_namespaces: strip_response_namespaces)
          end
          self
        end

        def request_body(body)
          @payload = body
          @render_request = ->(payload) { payload }
          self
        end

        def response_format_raw
          @parse_response = lambda_with_error_wrap(RAWResponseFormatError) do |payload|
            payload.body.force_encoding(::Encoding::BINARY)
            payload.body.valid_encoding? ? payload.body : payload.body.force_encoding(::Encoding::BINARY)
          end
          self
        end

        def request_format_multipart_form
          @content_type_header = nil

          @render_request = lambda_with_error_wrap(MultipartFormRequestFormatError) do |payload|
            payload&.each_with_object({}) do |(name, (value, content_type, original_filename)), rendered|
              rendered[name] = if content_type.present?
                                 Part.new(name, content_type, original_filename || ::File.basename(name), value.to_s)
                               else
                                 value
                               end
            end&.merge!(multipart: true) || {}
          end

          self
        end

        def request_format_www_form_urlencoded
          @content_type_header = 'application/x-www-form-urlencoded'
          @render_request = lambda_with_error_wrap(WWWFormURLEncodedRequestFormatError, &:to_param)
          self
        end

        def current_verb
          method
        end

        def current_url
          build_url
        end

        def auth_type(auth_type)
          @auth_type = auth_type
          self
        end

        def tls_client_cert(certificate:, key:, passphrase: nil, intermediates: [])
          @ssl_client_cert = OpenSSL::X509::Certificate.new(certificate)
          @ssl_client_key = OpenSSL::PKey::RSA.new(key, passphrase)
          @ssl_client_intermediate_certs = Array.wrap(intermediates).compact.map do |intermediate|
            OpenSSL::X509::Certificate.new(intermediate)
          end
          self
        rescue OpenSSL::OpenSSLError => e
          Kernel.raise(RequestTLSCertificateFormatError, e)
        end

        def tls_server_certs(certificates:, strict: true)
          @ssl_cert_store ||= OpenSSL::X509::Store.new
          @ssl_cert_store.set_default_paths unless strict
          Array.wrap(certificates).each do |certificate|
            @ssl_cert_store.add_cert(OpenSSL::X509::Certificate.new(certificate))
          end
          self
        rescue OpenSSL::OpenSSLError => e
          Kernel.raise(RequestTLSCertificateFormatError, e)
        end

        def puts(*args)
          ::Kernel.puts(*args)
        end

        def try(*args, &block)
          execute!.try(*args, &block)
        end

        private

        attr_reader :method

        def response
          authorized do
            begin
              request = RestClientRequest.new(rest_request_params)
              response = execute_request(request)
            rescue RestClient::Unauthorized => e
              Kernel.raise e unless @digest_auth

              @digest_auth = false
              headers('Authorization' => Net::HTTP::DigestAuth.new.auth_header(
                URI.parse(build_url),
                e.response.headers[:www_authenticate],
                method.to_s.upcase
              ))
              request = RestClientRequest.new(rest_request_params)
              response = execute_request(request)
            end
            detect_error!(response.body)
            parsed_response = @parse_response.call(response)
            detect_error!(parsed_response)
            apply_after_response(response.code, parsed_response, response.headers)
          end
        end

        def execute_request(request)
          if @follow_redirection.nil?
            request.execute
          else
            request.execute do |res|
              case res.code
              when 301, 302, 307, 308
                if @follow_redirection
                  res.follow_redirection
                else
                  res
                end
              else
                res.return!
              end
            end
          end
        end

        def rest_request_params
          {
            method: method,
            url: build_url,
            headers: build_headers,
            payload: @render_request.call(@payload),
            case_sensitive_headers: @case_sensitive_headers.transform_keys(&:to_s)
          }.tap do |request_hash|
            if @ssl_client_cert.present? && @ssl_client_key.present?
              request_hash[:ssl_client_cert] = @ssl_client_cert
              request_hash[:ssl_client_key] = @ssl_client_key
              if @ssl_client_intermediate_certs.present?
                request_hash[:ssl_extra_chain_cert] = @ssl_client_intermediate_certs
              end
            end
            request_hash[:ssl_cert_store] = @ssl_cert_store if @ssl_cert_store
          end
        end

        def build_url
          uri = if @base_uri
                  URI.parse(@base_uri).merge(@uri)
                else
                  URI.parse(@uri)
                end

          return uri.to_s unless @params || @user || @password

          unless @digest_auth
            uri.user = URI.encode_www_form_component(@user) if @user
            uri.password = URI.encode_www_form_component(@password) if @password
          end

          return uri.to_s unless @params

          query = uri.query.to_s.split('&').select(&:present?).join('&').presence
          params = @params.to_param.presence
          if query && params
            uri.query = "#{query}&#{params}"
          elsif params
            uri.query = params
          end

          uri.to_s
        end

        def build_headers
          headers = @headers
          if @content_type_header.present? && headers.keys.none? { |key| /^content[\-_]type$/i =~ key }
            headers[:content_type] = @content_type_header
          end
          if @accept_header && headers.keys.none? { |key| /^accept$/i =~ key }
            headers[:accept] = @accept_header
          end
          headers.compact
        end

        def detect_error!(response)
          return unless authorized?

          error_patterns = connection.authorization.detect_on
          return unless error_patterns.any? { |pattern| pattern === response rescue false }

          Kernel.raise(CustomRequestError, response.to_s)
        end

        def after_error_response_matches?(exception)
          return if @after_error_response_matches.blank?

          @after_error_response_matches.find do |match|
            case match
            when ::Integer
              match == exception.http_code
            when ::String
              exception.message.to_s.match(match) || exception.http_body&.match(match)
            when ::Regexp
              match =~ exception.message || match =~ exception.http_body
            end
          end
        end

        def apply_after_error_response(exception)
          within_action_context(
            exception.http_code,
            exception.http_body,
            HashWithIndifferentAccess.wrap(exception.http_headers),
            exception.message,
            &@after_error_response
          )
        end

        def apply_after_response(code, parsed_response, headers)
          encoded_headers = (headers || {}).each_with_object(HashWithIndifferentAccess.new) do |(k, v), h|
            h[k] = Workato::Utilities::Encoding.force_best_encoding!(v.to_s)
          end
          within_action_context(code, parsed_response, encoded_headers, &@after_response)
        end

        def within_action_context(*args, &block)
          (@action || self).instance_exec(*args, &block)
        end

        sig { returns(T::Boolean) }
        def authorized?
          !!@connection&.authorization?
        end

        def authorized
          return yield unless authorized?

          apply = connection.authorization.source[:apply] || connection.authorization.source[:credentials]
          return yield unless apply

          first = true
          begin
            settings = connection.settings
            if connection.authorization.oauth2?
              instance_exec(settings, settings[:access_token], @auth_type, &apply)
            else
              instance_exec(settings, @auth_type, &apply)
            end
            yield
          rescue RestClient::Exception, CustomRequestError => e
            Kernel.raise e unless first
            Kernel.raise e unless refresh_authorization!(e.try(:http_code), e.try(:http_body), e.message)

            first = false
            retry
          end
        end

        sig do
          params(
            http_code: T.nilable(Integer),
            http_body: T.nilable(String),
            exception: T.nilable(String)
          ).returns(T::Boolean)
        end
        def refresh_authorization!(http_code, http_body, exception)
          return false unless connection.authorization.refresh?(http_code, http_body, exception)

          connection.update_settings!("Refresh token triggered on response \"#{exception}\"") do
            connection.authorization.refresh!(connection.settings)
          end
        end

        sig { returns(Connection) }
        def connection
          T.must(@connection)
        end

        def lambda_with_error_wrap(error_type, &block)
          Kernel.lambda do |payload|
            begin
              block.call(payload)
            rescue StandardError => e
              Kernel.raise error_type.new(e)
            end
          end
        end

        class Part < StringIO
          def initialize(path, content_type, original_filename, *args)
            super(*args)
            @path = path
            @content_type = content_type
            @original_filename = original_filename
          end

          attr_reader :path
          attr_reader :content_type
          attr_reader :original_filename
        end

        class RestClientRequest < ::RestClient::Request
          def initialize(args)
            super
            @ssl_opts[:extra_chain_cert] = args[:ssl_extra_chain_cert] if args.key?(:ssl_extra_chain_cert)
            @case_sensitive_headers = args[:case_sensitive_headers]
            @before_execution_proc = proc do |net_http_request, _args|
              net_http_request.case_sensitive_headers = args[:case_sensitive_headers]
            end
          end

          def ssl_extra_chain_cert
            @ssl_opts[:extra_chain_cert]
          end

          def processed_headers
            return @processed_headers if @case_sensitive_headers.blank?
            return @case_sensitive_headers if @processed_headers.blank?

            @processed_headers.merge(@case_sensitive_headers)
          end

          def net_http_object(hostname, port)
            net = super(hostname, port)
            net.extra_chain_cert = ssl_extra_chain_cert if ssl_extra_chain_cert
            net
          end
        end
        private_constant :RestClientRequest
      end
    end
  end
end
