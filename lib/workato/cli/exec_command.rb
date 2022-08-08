# typed: false
# frozen_string_literal: true

require 'thor'

module Workato
  module CLI
    class ExecCommand
      include Thor::Shell

      DebugExceptionError = Class.new(StandardError)

      def initialize(path:, options:)
        @path = path
        @options = options
      end

      def call
        load_from_default_files
        inspect_params(params)
        output = with_progress { execute_path }
        show_output(output)
        output
      end

      private

      attr_reader :path
      attr_reader :options

      # rubocop:disable Style/GuardClause
      def load_from_default_files
        if File.exist?(Workato::Connector::Sdk::DEFAULT_SCHEMAS_PATH)
          Workato::Connector::Sdk::WorkatoSchemas.from_json
        end
        if File.exist?(Workato::Connector::Sdk::DEFAULT_LOOKUP_TABLES_PATH)
          Workato::Connector::Sdk::LookupTables.from_yaml
        end
        if File.exist?(Workato::Connector::Sdk::DEFAULT_ACCOUNT_PROPERTIES_PATH)
          Workato::Connector::Sdk::AccountProperties.from_yaml
        end
        if File.exist?(Workato::Connector::Sdk::DEFAULT_ENCRYPTED_ACCOUNT_PROPERTIES_PATH)
          Workato::Connector::Sdk::AccountProperties.from_encrypted_yaml
        end
      end
      # rubocop:enable Style/GuardClause

      def params
        @params ||= {
          settings: settings,
          input: from_json(options[:input]),
          webhook_subscribe_output: from_json(options[:webhook_subscribe_output]),
          args: from_json(options[:args]).presence || [],
          extended_input_schema: from_json(options[:extended_input_schema]).presence || [],
          extended_output_schema: from_json(options[:extended_output_schema]).presence || [],
          config_fields: from_json(options[:config_fields]),
          closure: from_json(options[:closure], parse_json_times: true).presence,
          continue: from_json(options[:continue], parse_json_times: true),
          payload: from_json(options[:webhook_payload]),
          params: from_json(options[:webhook_params]),
          headers: from_json(options[:webhook_headers]),
          webhook_url: options[:webhook_url],
          oauth2_code: options[:oauth2_code],
          redirect_url: options[:redirect_url],
          refresh_token: options[:refresh_token],
          recipe_id: SecureRandom.uuid
        }
      end

      def connector
        @connector ||= Workato::Connector::Sdk::Connector.from_file(
          options[:connector] || Workato::Connector::Sdk::DEFAULT_CONNECTOR_PATH,
          settings
        )
      end

      def settings
        return @settings if defined?(@settings)

        settings_store = Workato::Connector::Sdk::Settings.new(
          path: options[:settings],
          name: options[:connection],
          key_path: options[:key]
        )
        @settings = settings_store.read

        Workato::Connector::Sdk::Connection.on_settings_update = lambda do |message, &refresher|
          begin
            $stdout.pause if verbose?
            say('')
            say(message)
            new_settings = refresher.call
            loop do
              answer = ask('Updated settings file with new connection attributes? (Yes or No)').to_s.downcase
              break new_settings if %w[n no].include?(answer)
              next unless %w[y yes].include?(answer)

              settings_store.update(new_settings)
              break new_settings
            end
          ensure
            $stdout.resume if verbose?
          end
        end

        @settings
      end

      def from_json(path, parse_json_times: false)
        old_parse_json_times = ActiveSupport.parse_json_times
        ::ActiveSupport.parse_json_times = parse_json_times
        path ? ::ActiveSupport::JSON.decode(File.read(path)) : {}
      ensure
        ::ActiveSupport.parse_json_times = old_parse_json_times
      end

      def inspect_params(params)
        return unless verbose?

        if params[:settings].present?
          say('SETTINGS')
          jj params[:settings]
        end

        say('INPUT')
        jj params[:input]
      end

      def execute_path
        connector.invoke(path, params)
      rescue Exception => e # rubocop:disable Lint/RescueException
        raise DebugExceptionError, e if options[:debug]

        raise
      end

      def show_output(output)
        if options[:output].present?
          File.open(options[:output], 'w') do |f|
            f.write(JSON.dump(output))
          end
        elsif options[:output].nil?
          say('OUTPUT') if verbose?
          jj output
        end
      end

      def verbose?
        !!options[:verbose]
      end

      def with_progress
        return yield unless verbose?

        require 'ruby-progressbar'

        say('')

        old_stdout = $stdout
        progress_bar = ProgressBar.create(total: nil, output: old_stdout)
        $stdout = ProgressLogger.new(progress_bar)
        RestClient.log = $stdout

        dots = Thread.start do
          loop do
            progress_bar.increment unless progress_bar.paused?
            sleep(0.2)
          end
        end
        output = yield
        dots.kill
        progress_bar.finish

        $stdout = old_stdout

        say('')

        output
      end

      class ProgressLogger < SimpleDelegator
        def initialize(progress)
          super($stdout)
          @progress = progress
        end

        delegate :log, :pause, :resume, to: :@progress

        alias << log
        alias write log
        alias puts log
        alias print log
      end
    end
  end
end
