# frozen_string_literal: true

module Workato::Connector::Sdk
  RSpec.describe Action do
    subject(:action) { described_class.new(action: action_definition, methods: methods) }

    let(:action_definition) do
      {
        'execute' => lambda do |settings, input, extended_input_schema, extended_output_schema|
          call('join', settings, input, extended_input_schema, extended_output_schema)
        end
      }
    end
    let(:methods) do
      {
        'join' => lambda do |settings, input, extended_input_schema, extended_output_schema|
          {
            settings: settings,
            input: input,
            extended_input_schema: extended_input_schema,
            extended_output_schema: extended_output_schema
          }
        end
      }
    end

    let(:settings) do
      { user: 'user', 'password' => 'password' }
    end
    let(:input) do
      { param1: 'value1' }
    end
    let(:extended_input_schema) do
      { field1: '1', 'field2' => 2 }
    end
    let(:extended_output_schema) do
      { field3: '3', 'field4' => 4 }
    end

    it 'executes execute block of the action' do
      output = action.execute(settings, input, [extended_input_schema], [extended_output_schema])
      expect(output).to eq(
        'settings' => settings.with_indifferent_access,
        'input' => input.with_indifferent_access,
        'extended_input_schema' => [extended_input_schema.with_indifferent_access],
        'extended_output_schema' => [extended_output_schema.with_indifferent_access]
      )
    end

    context 'when execute block is missing' do
      let(:action_definition) { {} }

      it { expect { action.execute }.to raise_error(InvalidDefinitionError) }
    end
  end
end
