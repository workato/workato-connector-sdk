# typed: false
# frozen_string_literal: true

module Workato::Connector::Sdk
  RSpec.describe Schema do
    subject(:schema) { described_class.new(schema: properties) }

    let(:int_field) { { name: :int_field, type: :integer, optional: false } }
    let(:float_field) { { name: 'float_field', type: 'number' } }
    let(:boolean_field) { { 'name' => :boolean_field, 'type' => :boolean } }
    let(:date_field) { { name: :date_field, type: :date } }
    let(:date_time_field) { { name: :date_time_field, type: :date_time } }
    let(:timestamp_time_field) { { name: :timestamp_time_field, type: :timestamp } }
    let(:string_field) { { name: :string_field } }

    let(:array_of_int_field) { { name: :array_of_int_field, type: :array, of: :integer } }
    let(:array_of_objects_field) do
      {
        name: :array_of_objects_field, type: :array,
        properties: [
          { name: :field1 }
        ]
      }
    end

    let(:object_field) do
      {
        name: :object_field, type: :object,
        properties: [
          { name: :prop1 }
        ]
      }
    end

    let(:with_toggle_field) do
      {
        name: :with_toggle_field, type: :integer, toggle_hint: 'toggle_hint',
        toggle_field: {
          name: :toggle_field,
          type: 'number'
        }
      }
    end

    let(:with_overridden_attributes) do
      {
        name: :with_overridden_attributes,
        type: :integer,
        control_type: :date_time,
        label: 'with_overridden_attributes',
        toggle_hint: 'toggle_hint',
        toggle_field: {
          name: :toggle_field,
          type: 'number',
          control_type: :text
        }
      }
    end

    let(:input) do
      {
        int_field: '42',
        'float_field' => '1.99',
        boolean_field: false,
        date_field: '02/12/2001',
        date_time_field: '02/12/2001 15:59:59',
        timestamp_time_field: '12/04/1961 06:07:00',
        string_field: 'Hello, World!',
        array_of_int_field: [1, 2, 3, '4', -1, '-10'],
        array_of_objects_field: [
          { field1: 'value1' }, { 'field1' => 'value2' }
        ],
        object: {
          prop1: 'value1'
        },
        with_toggle_field: '100',
        toggle_field: '1.99',
        unknown_field: 'unknown_field'
      }
    end

    let(:properties) do
      [
        int_field,
        float_field,
        boolean_field,
        date_field,
        date_time_field,
        timestamp_time_field,
        string_field,
        array_of_int_field,
        array_of_objects_field,
        object_field,
        with_toggle_field,
        with_overridden_attributes
      ]
    end

    it 'builds schema properties with default attributes' do
      expect(schema).to eq(
        [
          {
            'type' => 'integer',
            'name' => 'int_field',
            'control_type' => 'number',
            'label' => 'Int field',
            'optional' => false,
            'parse_output' => 'integer_conversion'
          },
          {
            'type' => 'number',
            'name' => 'float_field',
            'control_type' => 'number',
            'label' => 'Float field',
            'optional' => true,
            'parse_output' => 'float_conversion'
          },
          {
            'type' => 'number',
            'name' => 'boolean_field',
            'control_type' => 'number',
            'label' => 'Boolean field',
            'optional' => true,
            'parse_output' => 'float_conversion'
          },
          {
            'control_type' => 'date',
            'label' => 'Date field',
            'type' => 'date_time',
            'name' => 'date_field',
            'optional' => true,
            'render_input' => 'date_conversion',
            'parse_output' => 'date_conversion'
          },
          {
            'type' => 'date_time',
            'name' => 'date_time_field',
            'control_type' => 'date_time',
            'label' => 'Date time field',
            'optional' => true,
            'render_input' => 'date_time_conversion',
            'parse_output' => 'date_time_conversion'
          },
          {
            'type' => 'date_time',
            'name' => 'timestamp_time_field',
            'control_type' => 'date_time',
            'label' => 'Timestamp time field',
            'optional' => true,
            'render_input' => 'date_time_conversion',
            'parse_output' => 'date_time_conversion'
          },
          {
            'type' => 'string',
            'name' => 'string_field',
            'control_type' => 'text',
            'label' => 'String field',
            'optional' => true
          },
          {
            'type' => 'array',
            'name' => 'array_of_int_field',
            'label' => 'Array of int field',
            'optional' => true,
            'of' => 'integer'
          },
          {
            'type' => 'array',
            'name' => 'array_of_objects_field',
            'label' => 'Array of objects field',
            'optional' => true,
            'of' => 'object',
            'properties' => [
              {
                'control_type' => 'text',
                'label' => 'Field 1',
                'optional' => true,
                'type' => 'string',
                'name' => 'field1'
              }
            ]
          },
          {
            'label' => 'Object field',
            'type' => 'object',
            'name' => 'object_field',
            'optional' => true,
            'properties' => [
              {
                'control_type' => 'text',
                'label' => 'Prop 1',
                'optional' => true,
                'type' => 'string',
                'name' => 'prop1'
              }
            ]
          },
          {
            'control_type' => 'number',
            'label' => 'With toggle field',
            'type' => 'integer',
            'name' => 'with_toggle_field',
            'optional' => true,
            'toggle_hint' => 'toggle_hint',
            'toggle_field' => {
              'name' => 'toggle_field',
              'type' => 'number'
            },
            'parse_output' => 'integer_conversion'
          },
          {
            'type' => 'integer',
            'name' => 'with_overridden_attributes',
            'control_type' => 'date_time',
            'label' => 'with_overridden_attributes',
            'optional' => true,
            'parse_output' => 'integer_conversion',
            'toggle_hint' => 'toggle_hint',
            'toggle_field' => {
              'name' => 'toggle_field',
              'type' => 'number',
              'control_type' => 'text'
            }
          }
        ]
      )
    end

    describe '#trim' do
      subject(:output) { schema.trim(input) }

      let(:properties) { [int_field, float_field, boolean_field, with_toggle_field] }

      it 'keeps only expected fields' do
        expect(output).to eq(
          'int_field' => '42',
          'boolean_field' => false,
          'float_field' => '1.99',
          'with_toggle_field' => '100',
          'toggle_field' => '1.99'
        )
      end
    end

    describe '#apply' do
      subject(:output) do
        schema.apply(input, enforce_required: true) do |value, field|
          field.parse_output(field.render_input(value))
        end
      end

      it 'normalizes input values' do
        expect(output).to eq(
          {
            int_field: 42,
            float_field: 1.99,
            boolean_field: false,
            date_field: Date.parse('02/12/2001'),
            date_time_field: Time.zone.parse('02/12/2001 15:59:59'),
            timestamp_time_field: Time.zone.parse('12/04/1961 06:07:00'),
            string_field: 'Hello, World!',
            array_of_int_field: [1, 2, 3, '4', -1, '-10'],
            array_of_objects_field: [
              { field1: 'value1' }, { field1: 'value2' }
            ],
            object: {
              prop1: 'value1'
            },
            with_toggle_field: 100,
            toggle_field: '1.99',
            unknown_field: 'unknown_field'
          }.with_indifferent_access
        )
      end

      context 'when unsupported data type' do
        subject(:output) { schema.apply(input, enforce_required: false) }

        let(:input) { { symbol_field: :symbol_field } }
        let(:properties) { [{ name: :symbol_field }] }

        it 'converts to string' do
          expect { output }.to raise_error(ArgumentError, 'Unsupported data type: Symbol')
        end
      end

      context 'when type array' do
        subject(:output) do
          schema.apply(input, enforce_required: true) do |value, field|
            field.parse_output(field.render_input(value, format_array), format_array)
          end
        end

        let(:format_array) { ->(value) { value + value } }
        let(:input) { { array_field: %w[1 2 3] } }
        let(:properties) do
          [{ name: :array_field, type: :array, of: :integer }]
        end

        it 'applies to array and each field' do
          expect(output).to eq('array_field' => %w[1111 2222 3333 1111 2222 3333 1111 2222 3333 1111 2222 3333])
        end
      end

      context 'when require input is missing' do
        subject(:output) { schema.apply(input, enforce_required: true) }

        let(:input) { {} }

        it 'fails with error' do
          expect { output }.to raise_error(MissingRequiredInput, "'Int field' must be present")
        end
      end
    end
  end
end
