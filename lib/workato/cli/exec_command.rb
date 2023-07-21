# typed: true
# frozen_string_literal: true

require 'thor'
require 'active_support/json'
require_relative 'multi_auth_selected_fallback'

Method.prepend(T::CompatibilityPatches::MethodExtensions)

module Workato
  module CLI
    class ExecCommand
      include Thor::Shell
      include MultiAuthSelectedFallback

      DebugExceptionError = Class.new(StandardError)

      def initialize(path:, options:)
        @path = path
        @options = options
      end

      def call
        load_from_default_files
        inspect_params(params)
        output = with_progress { execute_path }
        show_output(output.as_json)
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
          from: options[:from].to_i,
          frame_size: options[:frame_size]&.to_i || Workato::Connector::Sdk::Stream::DEFAULT_FRAME_SIZE,
          recipe_id: Workato::Connector::Sdk::Operation.recipe_id!
        }.tap do |h|
          h[:to] = h[:from] + h[:frame_size] - 1
        end
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

        Workato::Connector::Sdk::Connection.multi_auth_selected_fallback = lambda do |options|
          next @selected_auth_type if @selected_auth_type

          with_user_interaction do
            @selected_auth_type = multi_auth_selected_fallback(options)
          end
        end

        Workato::Connector::Sdk::Connection.on_settings_update = lambda do |message, _settings_before, refresher|
          new_settings = refresher.call
          break unless new_settings
          break new_settings if @settings == new_settings

          with_user_interaction do
            loop do
              say(message)
              answer = ask('Updated settings file with new connection attributes? (Yes or No)').to_s.downcase
              break new_settings if %w[n no].include?(answer)
              next unless %w[y yes].include?(answer)

              @settings.merge!(new_settings)
              settings_store.update(new_settings)
              break new_settings
            end
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
        InvokePath.new(path: path, connector: connector, params: params).call
      rescue Workato::Connector::Sdk::InvalidMultiAuthDefinition => e
        raise "#{e.message}. Please ensure:\n" \
              "- 'selected' block is defined and returns value from 'options' list\n" \
              "- settings file contains value expected by 'selected' block\n\n" \
              'See more: https://docs.workato.com/developing-connectors/sdk/guides/authentication/multi_auth.html'
      rescue Exception => e # rubocop:disable Lint/RescueException
        raise DebugExceptionError, e if options[:debug]

        raise
      end

      def show_output(output)
        if options[:output].present?
          File.write(options[:output], JSON.dump(output))
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

      def with_user_interaction
        $stdout.pause if verbose?
        say('')

        yield
      ensure
        say('')
        $stdout.resume if verbose?
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

      class InvokePath
        extend T::Sig

        sig do
          params(
            path: String,
            connector: Workato::Connector::Sdk::Connector,
            params: T::Hash[Symbol, T.untyped]
          ).void
        end
        def initialize(path:, connector:, params:)
          @path = T.let(path, String)
          @connector = T.let(connector, Workato::Connector::Sdk::Connector)
          @params = T.let(params, T::Hash[Symbol, T.untyped])
        end

        sig { returns(T.untyped) }
        def call
          invoke_path
        end

        private

        sig { returns(String) }
        attr_reader :path

        sig { returns(Workato::Connector::Sdk::Connector) }
        attr_reader :connector

        sig { returns(T::Hash[Symbol, T.untyped]) }
        attr_reader :params

        sig { returns(T.untyped) }
        def invoke_path
          methods = path.split('.')
          method = methods.pop
          raise ArgumentError, 'path is not found' unless method

          object = methods.inject(connector) { |obj, m| obj.public_send(m) }
          output = invoke_method(object, method)
          if output.respond_to?(:invoke)
            invoke_method(output, :invoke)
          else
            output
          end
        end

        sig { params(object: T.untyped, method: T.any(Symbol, String)).returns(T.untyped) }
        def invoke_method(object, method)
          parameters = object.method(method).parameters.reject { |p| p[0] == :block }.map(&:second)
          args = params.values_at(*parameters)
          if parameters.last == :args
            args = args.take(args.length - 1) + Array.wrap(args.last).flatten(1)
          end
          object.public_send(method, *args)
        end
      end
      private_constant :InvokePath
    end
  end
end
