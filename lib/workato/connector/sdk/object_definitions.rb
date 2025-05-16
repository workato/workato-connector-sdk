# typed: strict
# frozen_string_literal: true

require_relative 'block_invocation_refinements'

module Workato
  module Connector
    module Sdk
      module SorbetTypes
        ObjectDefinitionOutput = T.type_alias { T::Array[ActiveSupport::HashWithIndifferentAccess] }
      end

      class ObjectDefinitions
        extend T::Sig

        using BlockInvocationRefinements # rubocop:disable Sorbet/Refinement core SDK feature

        sig do
          params(
            object_definitions: SorbetTypes::SourceHash,
            connection: Connection,
            methods: SorbetTypes::SourceHash
          ).void
        end
        def initialize(object_definitions:, connection:, methods:)
          @object_definitions_source = object_definitions
          @methods_source = methods
          @connection = connection
          @object_definitions = T.let({}, T::Hash[T.any(String, Symbol), ObjectDefinition])
          define_object_definition_methods
        end

        sig do
          params(
            settings: T.nilable(SorbetTypes::SettingsHash),
            config_fields: SorbetTypes::OperationInputHash
          ).returns(ActiveSupport::HashWithIndifferentAccess)
        end
        def lazy(settings = nil, config_fields = {})
          DupHashWithIndifferentAccess.new do |object_definitions, name|
            fields_proc = object_definitions_source.dig(name, :fields)
            raise Workato::Connector::Sdk::UnresolvedObjectDefinitionError, name unless fields_proc

            begin
              object_definitions[name] = create_operation.execute(settings, config_fields) do |connection, input|
                instance_exec(connection, input, object_definitions, &fields_proc)
              end
            rescue SystemStackError => e
              raise Workato::Connector::Sdk::CircleReferenceObjectDefinitionError.new(name, e.backtrace)
            end
          end
        end

        private

        sig { returns(SorbetTypes::SourceHash) }
        attr_reader :methods_source

        sig { returns(Connection) }
        attr_reader :connection

        sig { returns(SorbetTypes::SourceHash) }
        attr_reader :object_definitions_source

        sig { void }
        def define_object_definition_methods
          object_definitions_source.each do |(object, _definition)|
            define_singleton_method(object) do
              @object_definitions[object] ||= ObjectDefinition.new(name: object, object_definitions: self)
            end
          end
        end

        sig { returns(Operation) }
        def create_operation
          Operation.new(methods: methods_source, connection: connection)
        end

        class ObjectDefinition
          extend T::Sig

          sig { params(name: T.any(String, Symbol), object_definitions: ObjectDefinitions).void }
          def initialize(name:, object_definitions:)
            @name = name
            @object_definitions = object_definitions
          end

          sig do
            params(
              settings: T.nilable(SorbetTypes::SettingsHash),
              config_fields: SorbetTypes::OperationInputHash
            ).returns(SorbetTypes::ObjectDefinitionOutput)
          end
          def fields(settings = nil, config_fields = {})
            object_definitions_lazy_hash = @object_definitions.lazy(settings, config_fields)
            object_definitions_lazy_hash[@name]
          end
        end

        private_constant :ObjectDefinition

        class DupHashWithIndifferentAccess < ActiveSupport::HashWithIndifferentAccess
          extend T::Sig
          extend T::Generic

          K = type_member { { fixed: T.any(String, Symbol) } }
          V = type_member { { fixed: T.untyped } }
          Elem = type_member { { fixed: T.untyped } }

          sig { params(name: K).returns(V) }
          def [](name)
            super.deep_dup
          end
        end

        private_constant :DupHashWithIndifferentAccess
      end
    end
  end
end
