# frozen_string_literal: true

require_relative './block_invocation_refinements'

module Workato
  module Connector
    module Sdk
      class ObjectDefinitions
        using BlockInvocationRefinements

        def initialize(object_definitions:, connection:, methods:, settings:)
          @object_definitions_source = object_definitions
          @methods_source = methods
          @connection = connection
          @settings = settings
          define_object_definition_methods(object_definitions)
        end

        def lazy(settings = nil, config_fields = {})
          DupHashWithIndifferentAccess.new do |object_definitions, name|
            fields_proc = object_definitions_source[name][:fields]
            object_definitions[name] = Action.new(
              action: {
                execute: lambda do |connection, input|
                  instance_exec(connection, input, object_definitions, &fields_proc)
                end
              },
              methods: methods_source,
              connection: connection,
              settings: @settings
            ).execute(settings, config_fields)
          end
        end

        private

        attr_reader :methods_source,
                    :connection,
                    :settings,
                    :object_definitions_source

        def define_object_definition_methods(object_definitions)
          object_definitions.each do |(object, _definition)|
            define_singleton_method(object) do
              @object_definitions ||= {}
              @object_definitions[object] ||= ObjectDefinition.new(name: object, object_definitions: self)
            end
          end
        end

        class ObjectDefinition
          def initialize(name:, object_definitions:)
            @object_definitions = object_definitions
            @name = name
          end

          def fields(settings = nil, config_fields = {})
            object_definitions_lazy_hash = @object_definitions.lazy(settings, config_fields)
            object_definitions_lazy_hash[@name]
          end
        end

        class DupHashWithIndifferentAccess < HashWithIndifferentAccess
          def [](name)
            super.deep_dup
          end
        end

        private_constant 'ObjectDefinition'
        private_constant 'DupHashWithIndifferentAccess'
      end
    end
  end
end
