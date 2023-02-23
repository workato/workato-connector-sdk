# typed: false
# frozen_string_literal: true

RSpec.describe 'input_output_fields', :vcr do
  let(:connector) { Workato::Connector::Sdk::Connector.from_file('./spec/examples/input_output_fields/connector.rb') }

  let(:settings) { { user: 'user', password: 'password' } }
  let(:config_fields) { { type: :event } }

  describe 'input_fields' do
    it 'returns schema definition' do
      input_fields = connector.actions.test_action.input_fields(settings, config_fields)

      expect(input_fields).to contain_exactly(
        a_hash_including(
          'object_definitions' => {
            'event' => [HashWithIndifferentAccess]
          },
          'config_fields' => config_fields.with_indifferent_access,
          'connection' => settings.with_indifferent_access,
          'customer' => HashWithIndifferentAccess
        )
      )
    end
  end

  describe 'output_fields' do
    it 'returns schema definition' do
      input_fields = connector.actions.test_action.output_fields(settings, config_fields)

      expect(input_fields).to contain_exactly(
        a_hash_including(
          'object_definitions' => {
            'event' => [HashWithIndifferentAccess]
          },
          'config_fields' => config_fields.with_indifferent_access,
          'connection' => settings.with_indifferent_access,
          'customer' => HashWithIndifferentAccess
        )
      )
    end
  end

  describe 'object_definitions' do
    it 'returns schema definition' do
      event = connector.object_definitions.event.fields(settings, config_fields)

      expect(event).to be_a(Array)
      expect(event).to contain_exactly(name: 'type', type: 'event')
    end

    context 'when static' do
      it 'return schema definition' do
        static = connector.object_definitions.static.fields(settings, config_fields)

        expect(static).to include(name: 'id')
      end
    end
  end
end
