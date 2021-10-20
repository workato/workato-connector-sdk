# frozen_string_literal: true

require 'workato/web/app'

module Workato
  module CLI
    class OAuth2Command
      include Thor::Shell

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
        require_gems
        start_webrick

        say 'Local server is running. Allow following redirect_url in your OAuth2 provider:'
        say "\n"
        say redirect_url
        say ''

        say_status :success, "Open #{authorize_url} in browser"
        Launchy.open(authorize_url) do |exception|
          raise(Error, "Attempted to open #{authorize_url} and failed because #{exception}")
        end

        code = await_code
        say_status :success, "Receive OAuth2 code=#{code}"

        tokens = acquire_token(code)
        say_status :success, 'Receive OAuth2 tokens'
        jj tokens if verbose?

        settings_store.update(tokens)
        say_status :success, 'Update settings file'
      rescue Timeout::Error
        say "Have not received callback from OAuth2 provider in #{AWAIT_CODE_TIMEOUT_INTERVAL} seconds. Aborting!"
      rescue Errno::EADDRINUSE
        say "Port #{port} already in use. Try to use different port with --port=#{rand(10_000..65_664)}"
      rescue StandardError => e
        say e.message
      ensure
        stop_webrick
      end

      private

      attr_reader :https,
                  :base_url,
                  :redirect_url,
                  :port,
                  :options

      def verbose?
        !!options[:verbose]
      end

      def require_gems
        require 'oauth2'
        require 'launchy'
        require 'rack'
      end

      def start_webrick
        @thread = Thread.start do
          Rack::Handler::WEBrick.run(
            Workato::Web::App.new,
            {
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
        Rack::Handler::WEBrick.shutdown
        @thread.exit
      end

      def client
        @client ||= OAuth2::Client.new(
          connector.connection.authorization.client_id(settings),
          connector.connection.authorization.client_secret(settings),
          site: connector.connection.base_uri(settings),
          token_url: connector.connection.authorization.token_url(settings),
          redirect_uri: redirect_url
        )
      end

      def authorize_url
        return @authorize_url if defined?(@authorize_url)

        @authorize_url =
          if (authorization_url = connector.connection.authorization.authorization_url(settings))
            params = {
              client_id: connector.connection.authorization.client_id(settings),
              redirect_uri: redirect_url
            }
            uri = URI(authorization_url)
            uri.query = params.with_indifferent_access.merge(Rack::Utils.parse_nested_query(uri.query || '')).to_param
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
        @settings ||= settings_store.read
      end

      def connector
        @connector ||= Workato::Connector::Sdk::Connector.from_file(
          options[:connector] || Workato::Connector::Sdk::DEFAULT_CONNECTOR_PATH
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
        if connector.source.dig(:connection, :authorization, :acquire)
          tokens, _, extra_settings = connector.connection.authorization.acquire(settings, await_code, redirect_url)
          tokens ||= {}
          extra_settings ||= {}
          extra_settings.merge(tokens)
        else
          client.auth_code.get_token(code).to_hash
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
    end
  end
end
