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
        webhook_payload: 'spec/fixtures/webhook_payload.json',
        webhook_params: 'spec/fixtures/webhook_params.json',
        webhook_headers: 'spec/fixtures/webhook_headers.json',
        webhook_url: 'http://www.example.com',
        output: false
      }
    end

    let(:settings) { Workato::Connector::Sdk::Settings.from_file(options[:settings]) }
    let(:input) { JSON.parse(File.read(options[:input])) }
    let(:extended_input_schema) { JSON.parse(File.read(options[:extended_input_schema])) }
    let(:extended_output_schema) { JSON.parse(File.read(options[:extended_output_schema])) }
    let(:config_fields) { JSON.parse(File.read(options[:config_fields])) }
    let(:webhook_payload) { JSON.parse(File.read(options[:webhook_payload])) }
    let(:webhook_headers) { JSON.parse(File.read(options[:webhook_headers])) }
    let(:webhook_params) { JSON.parse(File.read(options[:webhook_params])) }
    let(:webhook_url) { options[:webhook_url] }

    {
      # actions
      'actions.echo_action.execute' => lambda do
        {
          connection: settings,
          input: input,
          extended_input_schema: extended_input_schema,
          extended_output_schema: extended_output_schema
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
          params: webhook_params
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
          webhook_subscribe_output: input
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

        it { expect(output).to eq('wrong number of arguments (given 3, expected 4)') }
      end

      context 'when more params than expected' do
        let(:path) { 'methods.echo_method2' }

        it { expect(output).to eq('wrong number of arguments (given 3, expected 2)') }
      end
    end
  end
end
