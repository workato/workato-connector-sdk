# typed: false
# frozen_string_literal: true

require 'thor'
require 'securerandom'
require 'workato/web/app'
require_relative 'multi_auth_selected_fallback'

module Workato
  module CLI
    class OAuth2Command
      include Thor::Shell
      include MultiAuthSelectedFallback

      AWAIT_CODE_TIMEOUT_INTERVAL = 180 # seconds
      AWAIT_CODE_SLEEP_INTERVAL = 5 # seconds

      DEFAULT_ADDRESS = '127.0.0.1'
      DEFAULT_PORT = '45555'

      def initialize(options: {})
        @options = options
        @port = options[:port] || DEFAULT_PORT
        @https = options[:https].is_true?
        @base_url = "#{https ? 'https' : 'http'}://localhost:#{port}"
        @redirect_url = "#{base_url}#{Workato::Web::App::CALLBACK_PATH}"
      end

      def call
        ensure_oauth2_type
        require_gems
        start_webrick

        say 'Local server is running. Allow following redirect_url in your OAuth2 provider:'
        say "\n"
        say redirect_url
        say ''

        say_status :success, "Open #{authorize_url} in browser"
        Launchy.open(authorize_url) do |exception|
          raise "Attempted to open #{authorize_url} and failed because #{exception}"
        end

        code = await_code
        say_status :success, "Receive OAuth2 code=#{code}"

        tokens = acquire_token(code)
        say_status :success, 'Receive OAuth2 tokens'
        say JSON.pretty_generate(tokens) if verbose?

        settings_store.update(tokens)
        say_status :success, 'Update settings file'
      rescue Timeout::Error
        raise "Have not received callback from OAuth2 provider in #{AWAIT_CODE_TIMEOUT_INTERVAL} seconds. Aborting!"
      rescue Errno::EADDRINUSE
        raise "Port #{port} already in use. Try to use different port with --port=#{rand(10_000..65_664)}"
      ensure
        stop_webrick
      end

      private

      attr_reader :https
      attr_reader :base_url
      attr_reader :redirect_url
      attr_reader :port
      attr_reader :options

      def verbose?
        !!options[:verbose]
      end

      def require_gems
        require 'rest-client'
        require 'launchy'
        require 'rack'
      end

      def start_webrick
        @thread = Thread.start do
          Rack::Handler::WEBrick.run(
            Workato::Web::App.new,
            **{
              Port: port,
              BindAddress: options[:ip] || DEFAULT_ADDRESS,
              SSLEnable: https,
              SSLVerifyClient: OpenSSL::SSL::VERIFY_NONE,
              SSLCertName: [%w[CN localhost]]
            }.tap do |server_options|
              unless verbose?
                server_options[:AccessLog] = []
                server_options[:Logger] = WEBrick::Log.new($stderr, 0)
              end
            end
          )
        end
        @thread.abort_on_exception = true
      end

      def stop_webrick
        return unless @thread

        Rack::Handler::WEBrick.shutdown
        @thread.join
        @thread.exit
      end

      def ensure_oauth2_type
        unless connector.connection.authorization.oauth2?
          raise 'Authorization type is not OAuth2. ' \
                'For multi-auth connector ensure correct auth type was used. ' \
                "Expected: 'oauth2', got: '#{connector.connection.authorization.type}'"
        end
      rescue Workato::Connector::Sdk::InvalidMultiAuthDefinition => e
        raise "#{e.message}. Please ensure:\n" \
              "- 'selected' block is defined and returns value from 'options' list\n" \
              "- settings file contains value expected by 'selected' block\n\n" \
              'See more: https://docs.workato.com/developing-connectors/sdk/guides/authentication/multi_auth.html'
      end

      def authorize_url
        return @authorize_url if defined?(@authorize_url)

        @authorize_url =
          if (authorization_url = connector.connection.authorization.authorization_url)
            params = {
              state: SecureRandom.hex(8),
              client_id: connector.connection.authorization.client_id,
              redirect_uri: redirect_url
            }.with_indifferent_access
            uri = URI(authorization_url)
            uri.query = params.merge(Rack::Utils.parse_nested_query(uri.query || '')).to_param
            uri.to_s
          end
      end

      def settings_store
        @settings_store ||= Workato::Connector::Sdk::Settings.new(
          path: options[:settings],
          name: options[:connection],
          key_path: options[:key]
        )
      end

      def settings
        return @settings if defined?(@settings)

        @settings = settings_store.read

        Workato::Connector::Sdk::Connection.multi_auth_selected_fallback = lambda do |options|
          next @selected_auth_type if @selected_auth_type

          with_user_interaction do
            @selected_auth_type = multi_auth_selected_fallback(options)
          end
        end

        @settings
      end

      def connector
        @connector ||= Workato::Connector::Sdk::Connector.from_file(
          options[:connector] || Workato::Connector::Sdk::DEFAULT_CONNECTOR_PATH,
          settings
        )
      end

      def await_code
        code_uri = URI("#{base_url}#{Workato::Web::App::CODE_PATH}")

        Timeout.timeout(AWAIT_CODE_TIMEOUT_INTERVAL) do
          loop do
            response = get(code_uri) rescue nil
            break response if response.present?

            sleep(AWAIT_CODE_SLEEP_INTERVAL)
          end
        end
      end

      def acquire_token(code)
        if connector.connection.authorization.source[:acquire]
          tokens, _, extra_settings = connector.connection.authorization.acquire(nil, code, redirect_url)
          tokens ||= {}
          extra_settings ||= {}
          extra_settings.merge(tokens)
        else
          response = RestClient.post(
            connector.connection.authorization.token_url,
            code: code,
            grant_type: :authorization_code,
            client_id: connector.connection.authorization.client_id,
            client_secret: connector.connection.authorization.client_secret,
            redirect_uri: redirect_url
          )
          JSON.parse(response.body).to_hash
        end
      end

      def get(uri)
        http = Net::HTTP.new(uri.host, uri.port)
        if https
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end

        request = Net::HTTP::Get.new(uri.request_uri)

        response = http.request(request)
        response.body
      end

      def with_user_interaction
        say('')
        yield
      ensure
        say('')
      end
    end
  end
end
