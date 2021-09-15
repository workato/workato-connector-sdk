# frozen_string_literal: true

require 'thor'
require 'workato/connector/sdk'
require_relative './exec_command'
require_relative './edit_command'
require_relative './generate_command'
require_relative './push_command'
require_relative './generators/connector_generator'
require_relative './generators/master_key_generator'

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
                               desc: 'Path to plain or encrypted file with connection configs, '\
                                     'passwords, tokens, secrets etc',
                               lazy_default: Workato::Connector::Sdk::DEFAULT_ENCRYPTED_SETTINGS_PATH
      method_option :connection, type: :string, aliases: '-n',
                                 desc: 'Connection name if settings file contains multiple settings'
      method_option :key, type: :string, aliases: '-k',
                          lazy_default: Workato::Connector::Sdk::DEFAULT_MASTER_KEY_PATH,
                          desc: 'Path to file with encrypt/decrypt key. '\
                          "NOTE: key from #{Workato::Connector::Sdk::DEFAULT_MASTER_KEY_ENV} has higher priority"
      method_option :input, type: :string, aliases: '-i', desc: 'Path to file with input JSON'
      method_option :closure, type: :string, desc: 'Path to file with next poll closure JSON'
      method_option :args, type: :string, aliases: '-a', desc: 'Path to file with method arguments JSON'
      method_option :extended_input_schema, type: :string,
                                            desc: 'Path to file with extended input schema definition JSON'
      method_option :extended_output_schema, type: :string,
                                             desc: 'Path to file with extended output schema definition JSON'
      method_option :config_fields, type: :string, desc: 'Path to file with config fields JSON'
      method_option :webhook_payload, type: :string, aliases: '-w', desc: 'Path to file with webhook payload JSON'
      method_option :webhook_params, type: :string, desc: 'Path to file with webhook params JSON'
      method_option :webhook_headers, type: :string, desc: 'Path to file with webhook headers JSON'
      method_option :webhook_url, type: :string, desc: 'Webhook URL for automatic webhook subscription'
      method_option :output, type: :string, aliases: '-o', desc: 'Write output to JSON file'

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
                          desc: 'Path to file with encrypt/decrypt key. '\
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

      desc 'push <FOLDER>', "Upload and release connector's code"
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
                    type: :string,
                    desc: 'Email for accessing Workato API or '\
                          "set #{Workato::CLI::PushCommand::WORKATO_API_EMAIL_ENV} env"
      method_option :api_token,
                    type: :string,
                    desc: 'Token for accessing Workato API or ' \
                          "set #{Workato::CLI::PushCommand::WORKATO_API_TOKEN_ENV} env"
      method_option :environment,
                    type: :string,
                    enum: Workato::CLI::PushCommand::ENVIRONMENTS.keys,
                    default: 'live',
                    desc: 'Server to push connector code to'

      def push(folder)
        PushCommand.new(
          folder: folder,
          options: options
        ).call
      end
    end
  end
end
