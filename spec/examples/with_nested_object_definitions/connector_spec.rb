# frozen_string_literal: true

RSpec.describe 'with nested object definitions', :vcr do
  let(:connector) do
    Workato::Connector::Sdk::Connector.from_file('./spec/examples/with_nested_object_definitions/connector.rb')
  end

  let(:settings) { { user: 'user', password: 'password' } }
  let(:config_fields) { { type: :event } }

  describe 'compound_type' do
    let(:compound_type_definition) do
      [
        {
          name: 'object_of_object',
          type: 'object',
          properties: [
            { name: 'object_two_field' },
            {
              name: 'object_of_object_one',
              type: 'object',
              properties: [
                { name: 'object_one_field' }
              ]
            }
          ]
        }.with_indifferent_access,
        {
          name: 'array_of_objects',
          type: 'array',
          of: 'object',
          properties: [
            { name: 'object_one_field' }
          ]
        }.with_indifferent_access
      ]
    end

    describe 'object definition' do
      subject(:compound_type) { connector.object_definitions.compound_type.fields(settings, config_fields) }

      it 'returns schema definition' do
        expect(compound_type).to be_kind_of(Array)
        expect(compound_type).to match_array(compound_type_definition)
      end
    end

    describe 'input_fields' do
      subject(:input_fields) { connector.actions.test_action.input_fields(settings, config_fields) }

      it 'returns schema definition' do
        expect(input_fields).to match_array(compound_type_definition)
      end
    end

    describe 'output_fields' do
      subject(:output_fields) { connector.actions.test_action.output_fields(settings, config_fields) }

      it 'returns schema definition' do
        expect(output_fields).to match_array(compound_type_definition)
      end
    end
  end
end
