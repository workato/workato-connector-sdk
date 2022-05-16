# frozen_string_literal: true

require_relative '../../../lib/workato/cli/exec_command'

module Workato::CLI
  RSpec.describe ExecCommand do
    subject(:output) { described_class.new(path: path, options: options).call }

    let(:options) do
      {
        connector: 'spec/fixtures/connectors/echo.rb',
        settings: 'spec/fixtures/settings.yaml',
        input: 'spec/fixtures/input.json',
        args: 'spec/fixtures/args.json',
        extended_input_schema: 'spec/fixtures/extended_input_schema.json',
        extended_output_schema: 'spec/fixtures/extended_output_schema.json',
        config_fields: 'spec/fixtures/config_fields.json',
        closure: 'spec/fixtures/closure.json',
        continue: 'spec/fixtures/continue.json',
        webhook_payload: 'spec/fixtures/webhook_payload.json',
        webhook_params: 'spec/fixtures/webhook_params.json',
        webhook_headers: 'spec/fixtures/webhook_headers.json',
        webhook_subscribe_output: 'spec/fixtures/webhook_subscribe_output.json',
        webhook_url: 'http://www.example.com',
        output: false,
        oauth2_code: '1234567890',
        redirect_url: 'http://localhost:3000/oauth2/callback',
        refresh_token: 'qwerty'
      }
    end

    let(:settings) { Workato::Connector::Sdk::Settings.from_file(options[:settings]) }
    let(:input) { JSON.parse(File.read(options[:input])) }
    let(:continue) { JSON.parse(File.read(options[:continue])) }
    let(:extended_input_schema) { JSON.parse(File.read(options[:extended_input_schema])) }
    let(:extended_output_schema) { JSON.parse(File.read(options[:extended_output_schema])) }
    let(:config_fields) { JSON.parse(File.read(options[:config_fields])) }
    let(:webhook_payload) { JSON.parse(File.read(options[:webhook_payload])) }
    let(:webhook_headers) { JSON.parse(File.read(options[:webhook_headers])) }
    let(:webhook_params) { JSON.parse(File.read(options[:webhook_params])) }
    let(:webhook_subscribe_output) { JSON.parse(File.read(options[:webhook_subscribe_output])) }
    let(:webhook_url) { options[:webhook_url] }

    {
      # actions
      'actions.with_schema_action' => lambda do
        {
          connection: settings,
          input: input,
          input_schema: [
            {
              'control_type' => 'number',
              'label' => 'Input',
              'name' => 'input',
              'optional' => true,
              'parse_output' => 'float_conversion',
              'type' => 'number'
            }
          ],
          output_schema: [
            {
              'label' => 'Input',
              'name' => 'input',
              'optional' => true,
              'properties' => [],
              'type' => 'object'
            },
            {
              'label' => 'Connection',
              'name' => 'connection',
              'optional' => true,
              'properties' => [],
              'type' => 'object'
            },
            {
              'label' => 'Input schema',
              'name' => 'input_schema',
              'optional' => true,
              'properties' => [],
              'type' => 'object'
            },
            {
              'label' => 'Output schema',
              'name' => 'output_schema',
              'optional' => true,
              'properties' => [],
              'type' => 'object'
            },
            {
              'label' => 'Continue',
              'name' => 'continue',
              'optional' => true,
              'properties' => [],
              'type' => 'object'
            }
          ]
        }.with_indifferent_access
      end,

      'actions.echo_action.execute' => lambda do
        {
          connection: settings,
          input: input,
          extended_input_schema: extended_input_schema,
          extended_output_schema: extended_output_schema,
          continue: continue
        }.with_indifferent_access
      end,

      'actions.echo_action.sample_output' => lambda do
        {
          connection: settings,
          input: input
        }.with_indifferent_access
      end,
      'actions.echo_action.input_fields' => lambda do
        {
          connection: settings,
          config_fields: config_fields
        }.with_indifferent_access
      end,
      'actions.echo_action.output_fields' => lambda do
        {
          connection: settings,
          config_fields: config_fields
        }.with_indifferent_access
      end,

      # triggers
      'triggers.with_schema_webhook_trigger' => lambda do
        {
          input: input,
          payload: webhook_payload,
          extended_input_schema: [
            {
              'control_type' => 'number',
              'label' => 'Input',
              'name' => 'input',
              'optional' => true,
              'parse_output' => 'float_conversion',
              'type' => 'number'
            }
          ],
          extended_output_schema: [
            { 'label' => 'Input', 'name' => 'input', 'optional' => true, 'properties' => [], 'type' => 'object' },
            { 'label' => 'Payload', 'name' => 'payload', 'optional' => true, 'properties' => [], 'type' => 'object' },
            {
              'label' => 'Extended input schema',
              'name' => 'extended_input_schema',
              'optional' => true, 'properties' => [],
              'type' => 'object'
            },
            {
              'label' => 'Extended output schema',
              'name' => 'extended_output_schema',
              'optional' => true,
              'properties' => [],
              'type' => 'object'
            },
            { 'label' => 'Headers', 'name' => 'headers', 'optional' => true, 'properties' => [], 'type' => 'object' },
            { 'label' => 'Params', 'name' => 'params', 'optional' => true, 'properties' => [], 'type' => 'object' },
            {
              'label' => 'Connection',
              'name' => 'connection',
              'optional' => true,
              'properties' => [],
              'type' => 'object'
            },
            {
              'label' => 'Webhook subscribe output',
              'name' => 'webhook_subscribe_output',
              'optional' => true,
              'properties' => [], 'type' => 'object'
            }
          ],
          headers: webhook_headers,
          params: webhook_params,
          connection: settings,
          webhook_subscribe_output: { 'webhook_subscribe_output' => true }
        }
      end,

      'triggers.with_schema_poll_trigger' => lambda do
        {
          events: [
            {
              connection: settings,
              input: input,
              closure: nil
            }
          ],
          can_poll_more: false,
          next_poll: Time
        }.with_indifferent_access
      end,

      'triggers.echo_trigger.poll' => lambda do
        {
          events: a_hash_including(
            connection: settings,
            input: input,
            closure: Time
          ),
          can_poll_more: false,
          next_poll: Time
        }.with_indifferent_access
      end,
      'triggers.echo_trigger.dedup' => lambda do
        {
          record: input
        }
      end,
      'triggers.echo_trigger.webhook_notification' => lambda do
        {
          input: input,
          payload: webhook_payload,
          extended_input_schema: extended_input_schema,
          extended_output_schema: extended_output_schema,
          headers: webhook_headers,
          params: webhook_params,
          connection: settings,
          webhook_subscribe_output: webhook_subscribe_output
        }
      end,
      'triggers.echo_trigger.webhook_subscribe' => lambda do
        {
          webhook_url: webhook_url,
          connection: settings,
          input: input,
          recipe_id: String,
          subscribed: true
        }.with_indifferent_access
      end,
      'triggers.echo_trigger.webhook_unsubscribe' => lambda do
        {
          webhook_subscribe_output: webhook_subscribe_output
        }.with_indifferent_access
      end,

      # methods
      'methods.echo_method3' => lambda do
        {
          a: 'arg_1', b: 'arg_2', c: 'arg_3'
        }.with_indifferent_access
      end,

      # pick_list
      'pick_lists.static' => lambda do
        {
          static: true
        }.with_indifferent_access
      end,

      'pick_lists.with_connection' => lambda do
        {
          connection: settings
        }.with_indifferent_access
      end,

      'pick_lists.with_kwargs' => lambda do
        {
          connection: settings,
          arg1: 'arg_1',
          arg2: 'arg_2',
          arg3: 3
        }.with_indifferent_access
      end,

      # object_definitions
      'object_definitions.echo.fields' => lambda do
        {
          connection: settings,
          config_fields: config_fields
        }.with_indifferent_access
      end,

      # connection
      'connection.base_uri' => lambda do
        {
          connection: settings
        }
      end,
      'connection.authorization.refresh_on' => -> { 401 },
      'connection.authorization.detect_on' => -> { 404 },
      'connection.authorization.client_id' => lambda do
        {
          connection: settings
        }
      end,
      'connection.authorization.client_secret' => lambda do
        {
          connection: settings
        }
      end,
      'connection.authorization.authorization_url' => lambda do
        {
          connection: settings
        }
      end,
      'connection.authorization.token_url' => lambda do
        {
          connection: settings
        }
      end,
      'connection.authorization.acquire' => lambda do
        {
          connection: settings,
          oauth2_code: options[:oauth2_code],
          redirect_url: options[:redirect_url]
        }.with_indifferent_access
      end,
      'connection.authorization.refresh' => lambda do
        {
          connection: settings,
          refresh_token: options[:refresh_token]
        }.with_indifferent_access
      end
    }.each do |path, expected_output|
      describe path do
        let(:path) { path }

        if path.start_with?('pick_lists')
          before { options[:args] = 'spec/fixtures/kwargs.json' }
        end

        it { is_expected.to include(instance_exec(&expected_output)) }
      end
    end

    describe 'connection.authorization.type' do
      let(:path) { 'connection.authorization.type' }

      it { is_expected.to eq(:oauth2) }
    end

    context 'when encrypted settings' do
      let(:path) { 'actions.echo_action.execute' }

      it 'parses settings' do
        stub_const('Workato::Connector::Sdk::Settings::DEFAULT_MASTER_KEY_PATH', 'spec/fixtures/master.key')
        options[:settings] = 'spec/fixtures/settings.yaml.enc'

        expect(output).to include({
          connection: Workato::Connector::Sdk::Settings.from_encrypted_file(options[:settings]),
          input: input,
          extended_input_schema: extended_input_schema,
          extended_output_schema: extended_output_schema
        }.with_indifferent_access)
      end
    end

    context 'when args do not match method definition' do
      context 'when less params than expected' do
        let(:path) { 'methods.echo_method4' }

        it { expect { output }.to raise_error(ArgumentError, /wrong number of arguments \(given 3, expected 4\)/) }
      end

      context 'when more params than expected' do
        let(:path) { 'methods.echo_method2' }

        it { expect { output }.to raise_error(ArgumentError, /wrong number of arguments \(given 3, expected 2\)/) }
      end
    end

    context 'when execute action without input' do
      let(:options) do
        {
          connector: 'spec/fixtures/connectors/echo.rb',
          output: false
        }
      end
      let(:path) { 'actions.with_schema_action' }

      it { expect(output).to include('connection' => {}, 'input' => {}) }
    end
  end
end
