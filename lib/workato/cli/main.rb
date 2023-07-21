# typed: true
# frozen_string_literal: true

require 'thor'
require 'workato/connector/sdk'
require_relative 'exec_command'
require_relative 'edit_command'
require_relative 'schema_command'
require_relative 'generate_command'
require_relative 'push_command'
require_relative 'oauth2_command'
require_relative 'generators/connector_generator'
require_relative 'generators/master_key_generator'

module Workato
  module CLI
    class Main < Thor
      class_option :verbose, type: :boolean

      desc 'exec <PATH>', 'Execute connector defined block'
      long_desc <<~HELP
        The 'workato exec' executes connector's lambda block at <PATH>.
        Lambda's parameters can be provided if needed, see options part.

        Example:

          workato exec actions.foo.execute # This executes execute block of foo action

          workato exec triggers.bar.poll # This executes poll block of bar action

          workato exec methods.bazz --args=input.json # This executes methods with params from input.json
      HELP

      method_option :connector, type: :string, aliases: '-c', desc: 'Path to connector source code',
                                lazy_default: Workato::Connector::Sdk::DEFAULT_CONNECTOR_PATH
      method_option :settings, type: :string, aliases: '-s',
                               desc: 'Path to plain or encrypted file with connection configs, ' \
                                     'passwords, tokens, secrets etc',
                               lazy_default: Workato::Connector::Sdk::DEFAULT_ENCRYPTED_SETTINGS_PATH
      method_option :connection, type: :string, aliases: '-n',
                                 desc: 'Connection name if settings file contains multiple settings'
      method_option :key, type: :string, aliases: '-k',
                          lazy_default: Workato::Connector::Sdk::DEFAULT_MASTER_KEY_PATH,
                          desc: "Path to file with encrypt/decrypt key.\n" \
                                "NOTE: key from #{Workato::Connector::Sdk::DEFAULT_MASTER_KEY_ENV} has higher priority"
      method_option :input, type: :string, aliases: '-i', desc: 'Path to file with input JSON'
      method_option :closure, type: :string, desc: 'Path to file with next poll closure JSON'
      method_option :continue, type: :string, desc: 'Path to file with next multistep action continue closure JSON'
      method_option :args, type: :string, aliases: '-a', desc: 'Path to file with method arguments JSON'
      method_option :extended_input_schema, type: :string,
                                            desc: 'Path to file with extended input schema definition JSON'
      method_option :extended_output_schema, type: :string,
                                             desc: 'Path to file with extended output schema definition JSON'
      method_option :config_fields, type: :string, desc: 'Path to file with config fields JSON'
      method_option :webhook_payload, type: :string, aliases: '-w', desc: 'Path to file with webhook payload JSON'
      method_option :webhook_params, type: :string, desc: 'Path to file with webhook params JSON'
      method_option :webhook_headers, type: :string, desc: 'Path to file with webhook headers JSON'
      method_option :webhook_subscribe_output, type: :string, desc: 'Path to file with webhook subscribe output JSON'
      method_option :webhook_url, type: :string, desc: 'Webhook URL for automatic webhook subscription'
      method_option :output, type: :string, aliases: '-o', desc: 'Write output to JSON file'
      method_option :oauth2_code, type: :string, desc: 'OAuth2 code exchange to tokens pair'
      method_option :redirect_url, type: :string, desc: 'OAuth2 callback url'
      method_option :refresh_token, type: :string, desc: 'OAuth2 refresh token'
      method_option :from, type: :numeric, desc: 'Stream byte offset to read from'
      method_option :frame_size, type: :numeric, desc: 'Stream chunk read size in bytes. Should be positive'

      method_option :debug, type: :boolean

      def exec(path)
        ExecCommand.new(
          path: path,
          options: options
        ).call
      end

      desc 'edit <PATH>', 'Edit encrypted file, e.g. settings.yaml.enc'

      method_option :key, type: :string, aliases: '-k',
                          lazy_default: Workato::Connector::Sdk::DEFAULT_MASTER_KEY_PATH,
                          desc: "Path to file with encrypt/decrypt key.\n" \
                                "NOTE: key from #{Workato::Connector::Sdk::DEFAULT_MASTER_KEY_ENV} has higher priority"

      def edit(path)
        EditCommand.new(
          path: path,
          options: options
        ).call
      end

      def self.exit_on_failure?
        true
      end

      long_desc <<~HELP
        The 'workato new' command creates a new Workato connector with a default
        directory structure and configuration at the path you specify.

        Example:
          workato new ~/dev/workato/random

          This generates a skeletal custom connector in ~/dev/workato/random.
      HELP
      register(Generators::ConnectorGenerator, 'new', 'new <CONNECTOR_PATH>', 'Inits new connector folder')

      desc 'generate <SUBCOMMAND>', 'Generates code from template'
      subcommand('generate', GenerateCommand)

      desc 'push', "Upload and release connector's code"
      method_option :title,
                    type: :string,
                    aliases: '-t',
                    desc: 'Connector title on the Workato Platform'
      method_option :description,
                    type: :string,
                    aliases: '-d',
                    desc: 'Path to connector description: Markdown or plain text'
      method_option :logo,
                    type: :string,
                    aliases: '-l',
                    desc: 'Path to connector logo: png or jpeg file'
      method_option :notes,
                    type: :string,
                    aliases: '-n',
                    desc: 'Release notes'
      method_option :connector,
                    type: :string,
                    aliases: '-c',
                    desc: 'Path to connector source code',
                    lazy_default: Workato::Connector::Sdk::DEFAULT_CONNECTOR_PATH
      method_option :api_email,
                    hide: true,
                    type: :string,
                    desc: "Email for accessing Workato API.\n" \
                          "If present overrides value from #{Workato::Connector::Sdk::WORKATO_API_EMAIL_ENV} " \
                          'environment variable.'
      method_option :api_token,
                    type: :string,
                    desc: "Token for accessing Workato API.\n" \
                          "If present overrides value from #{Workato::Connector::Sdk::WORKATO_API_TOKEN_ENV} " \
                          'environment variable.'
      method_option :environment,
                    type: :string,
                    desc: "Data center specific URL to push connector code.\n" \
                          "If present overrides value from #{Workato::Connector::Sdk::WORKATO_BASE_URL_ENV} " \
                          "environment variable.\n" \
                          "Examples: 'https://app.workato.com', 'https://app.eu.workato.com'"
      method_option :folder,
                    type: :string,
                    desc: 'Folder ID if you what to push to folder other than Home'

      def push
        PushCommand.new(
          options: options
        ).call
      end

      desc 'oauth2', 'Implements OAuth Authorization Code flow'

      method_option :connector,
                    type: :string,
                    aliases: '-c',
                    desc: 'Path to connector source code',
                    lazy_default: Workato::Connector::Sdk::DEFAULT_CONNECTOR_PATH
      method_option :settings,
                    type: :string,
                    aliases: '-s',
                    desc: 'Path to plain or encrypted file with connection configs, passwords, tokens, secrets etc',
                    lazy_default: Workato::Connector::Sdk::DEFAULT_ENCRYPTED_SETTINGS_PATH
      method_option :connection,
                    type: :string,
                    aliases: '-n',
                    desc: 'Connection name if settings file contains multiple settings'
      method_option :key,
                    type: :string,
                    aliases: '-k',
                    lazy_default: Workato::Connector::Sdk::DEFAULT_MASTER_KEY_PATH,
                    desc: "Path to file with encrypt/decrypt key.\n" \
                          "NOTE: key from #{Workato::Connector::Sdk::DEFAULT_MASTER_KEY_ENV} has higher priority"
      method_option :port,
                    type: :string,
                    desc: 'Listen requests on specific port',
                    default: Workato::CLI::OAuth2Command::DEFAULT_PORT
      method_option :ip,
                    type: :string,
                    desc: 'Listen requests on specific interface',
                    default: Workato::CLI::OAuth2Command::DEFAULT_ADDRESS
      method_option :https,
                    type: :boolean,
                    desc: 'Start HTTPS server using self-signed certificate'

      def oauth2
        OAuth2Command.new(
          options: options
        ).call
      end

      desc 'version', 'Shows gem version'
      def version
        puts Workato::Connector::Sdk::VERSION
      end

      class << self
        def print_options(shell, options, group_name = nil)
          return if options.empty?

          list = []
          padding = options.map { |o| o.aliases.size }.max.to_i * 4

          options.each do |option|
            next if option.hide

            description = []
            description_lines = option.description ? option.description.split("\n") : []
            first_line = description_lines.shift
            description << [option.usage(padding), first_line ? "# #{first_line}" : '']
            description_lines.each do |line|
              description << ['', "# #{line}"]
            end

            list.concat(description)
            list << ['', "# Default: #{option.default}"] if option.show_default?
            list << ['', "# Possible values: #{option.enum.join(', ')}"] if option.enum
          end

          shell.say(group_name ? "#{group_name} options:" : 'Options:')
          shell.print_table(list, indent: 2)
          shell.say ''
        end
      end
    end
  end
end
