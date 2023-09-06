# typed: false
# frozen_string_literal: true

module Workato
  module Connector
    module Sdk
      class Schema < SimpleDelegator
        def initialize(schema: [])
          super(Fields.new(::Array.wrap(schema).map { |i| Utilities::HashWithIndifferentAccess.wrap(i) }))
        end

        def trim(input)
          Utilities::HashWithIndifferentAccess.wrap(input).keep_if { |property_name| includes_property?(property_name) }
        end

        def apply(input, enforce_required:, &block)
          Utilities::HashWithIndifferentAccess.wrap(input).tap do |input_with_indifferent_access|
            apply_to_hash(self, input_with_indifferent_access, enforce_required: enforce_required, &block)
          end
        end

        def +(other)
          if other.is_a?(Schema)
            Schema.new.tap do |schema|
              schema.__setobj__(__getobj__ + other.__getobj__)
            end
          else
            Schema.new(schema: __getobj__ + other)
          end
        end

        private

        def includes_property?(name)
          find_property_by_name(name).present?
        end

        def find_property_by_name(name)
          find do |property|
            (property[:name].to_s == name.to_s) || (property.dig(:toggle_field, :name).to_s == name.to_s)
          end
        end

        def apply_to_hash(properties, object, enforce_required: false, &block)
          return if properties.blank? || object.nil?

          properties.each do |property|
            apply_to_value(property, object, property[:name], object[property[:name]], &block)
            if (toggle_property = property[:toggle_field])
              apply_to_value(toggle_property, object, toggle_property[:name], object[toggle_property[:name]], &block)
            end

            next unless enforce_required
            next if optional_or_present?(property, object) || optional_or_present?(property[:toggle_field], object)

            raise MissingRequiredInput.new(property[:label], property.dig(:toggle_field, :label))
          end
        end

        def optional_or_present?(property, object)
          property.present? && (
            property[:optional] ||
              property[:runtime_optional] ||
              (value = object[property[:name]]).present? ||
              value.is_a?(FalseClass) ||
              (value.is_a?(::String) && !value.empty?)
          )
        end

        def apply_to_array(property, array, &block)
          array.each_with_index do |item, index|
            apply_to_value(property, array, index, item, &block)
          end
        end

        def apply_to_value(property, container, index, value, &block)
          return unless property.present? && value.present?

          if value.respond_to?(:each_key)
            apply_to_hash(property[:properties], value, &block)
          elsif value.respond_to?(:each_with_index)
            apply_to_array(property, value, &block)
          end

          container[index] = if !value.nil? && block
                               normalize_value(yield(value, property))
                             else
                               normalize_value(value)
                             end
        end

        def normalize_value(value)
          return value if value.blank?

          case value
          when ::Time
            return Type::Time.from_time(value)
          when ::DateTime
            return Type::Time.from_date_time(value)
          when ::Date
            return value.to_date
          when ::Numeric, ::TrueClass, ::FalseClass, Workato::Types::Binary, Workato::Types::UnicodeString,
            ::Array, ::Hash, Stream::Proxy
            return value
          when Extension::Array::ArrayWhere
            return value.to_a
          when ::String
            if value.encoding == Encoding::ASCII_8BIT
              return Workato::Types::Binary.new(value)
            end

            return Workato::Types::UnicodeString.new(value)
          else
            if value.respond_to?(:to_time)
              return Type::Time.from_time(value.to_time)
            end

            if value.respond_to?(:read) && value.respond_to?(:rewind)
              value.rewind
              return Workato::Types::Binary.new(value.read.force_encoding(Encoding::ASCII_8BIT))
            end
          end

          raise ArgumentError, "Unsupported data type: #{value.class}"
        end
      end

      private_constant :Schema

      class Fields < ::Array
        def initialize(fields)
          ::Array.wrap(fields).each do |field|
            field = prepare_attributes(field)
            self << field_with_defaults(field)
          end
        end

        private

        def prepare_attributes(field)
          if (render_input = field.delete(:convert_input) || field[:render_input])
            field[:render_input] = render_input.is_a?(Proc) ? nil : render_input
          end
          if (parse_output = field.delete(:convert_output) || field[:parse_output])
            field[:parse_output] = parse_output.is_a?(Proc) ? nil : parse_output
          end
          field[:optional] = true unless field.key?(:optional)
          field[:label] ||= field[:name].labelize

          clean_values(field)

          if (toggle_field = field[:toggle_field]).present?
            raise InvalidSchemaError, 'toggle_hint not present' if field[:toggle_hint].blank?

            unless toggle_field[:name].present? && toggle_field[:type].present?
              raise InvalidSchemaError, 'toggle_field not complete'
            end

            if toggle_field[:optional].present? && (toggle_field[:optional] != field[:optional])
              raise InvalidSchemaError, 'toggle field cannot change optional attribute'
            end

            field[:toggle_field] = field_with_defaults(field[:toggle_field]).tap do |tg_field|
              tg_field.except!(:render_input, :parse_output, :control_type)
              tg_field[:control_type] = toggle_field[:control_type]
              clean_values(tg_field)
            end
          end

          if field[:control_type].try(:start_with?, 'small-')
            field[:control_type].remove!(/^small-/)
          elsif field[:control_type].try(:start_with?, 'medium-')
            field[:control_type].remove!(/^medium-/)
          end

          field
        end

        def clean_values(field)
          field.transform_values! do |value|
            next value if value.is_a?(FalseClass)

            value.presence && ((value.is_a?(::Symbol) && value.to_s) || value)
          end
          field.compact!
          field
        end

        def field_with_defaults(field)
          type = field.delete(:type).to_s

          case type
          when 'integer'
            Schema::Field::Integer.new(field)
          when 'number', 'boolean'
            Schema::Field::Number.new(field)
          when 'date_time', 'timestamp'
            Schema::Field::DateTime.new(field)
          when 'date'
            Schema::Field::Date.new(field)
          when 'object'
            field[:properties] = Fields.new(field[:properties])
            field.delete(:control_type)
            Schema::Field::Object.new(field)
          when 'array'
            of = field[:of] = (field[:of] || 'object').to_s
            if of == 'object'
              field[:properties] = Fields.new(field[:properties])
            else
              field.merge(
                field_with_defaults(field.merge(type: of)).except(:render_input, :parse_output)
              )
            end
            Schema::Field::Array.new(field)
          else
            Schema::Field::String.new(field)
          end
        end
      end

      private_constant :Fields
    end
  end
end

require_relative 'schema/field/array'
require_relative 'schema/field/date'
require_relative 'schema/field/date_time'
require_relative 'schema/field/integer'
require_relative 'schema/field/number'
require_relative 'schema/field/object'
require_relative 'schema/field/string'

require_relative 'schema/type/time'
