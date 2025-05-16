# typed: strict
# frozen_string_literal: true

require_relative 'dsl'
require_relative 'block_invocation_refinements'
require_relative 'schema'

module Workato
  module Connector
    module Sdk
      module SorbetTypes
        OperationInputHash = T.type_alias { T::Hash[T.any(Symbol, String), T.untyped] }

        OperationExecuteProc = T.type_alias do
          T.proc.params(
            arg0: ActiveSupport::HashWithIndifferentAccess,
            arg1: ActiveSupport::HashWithIndifferentAccess,
            arg2: T.any(Schema, T::Array[ActiveSupport::HashWithIndifferentAccess]),
            arg3: T.any(Schema, T::Array[ActiveSupport::HashWithIndifferentAccess]),
            arg4: ActiveSupport::HashWithIndifferentAccess
          ).returns(
            T.untyped
          )
        end

        OperationSchema = T.type_alias do
          T.any(Schema, T::Array[T::Hash[T.any(Symbol, String), T.untyped]])
        end

        OperationSchemaProc = T.type_alias do
          T.proc.params(
            arg0: ActiveSupport::HashWithIndifferentAccess,
            arg1: ActiveSupport::HashWithIndifferentAccess,
            arg2: ActiveSupport::HashWithIndifferentAccess
          ).returns(
            T.nilable(T.any(SorbetTypes::OperationSchema, T::Hash[T.any(Symbol, String), T.untyped]))
          )
        end
      end

      class Operation
        extend T::Sig

        include Dsl::Global
        include Dsl::AWS
        include Dsl::HTTP
        include Dsl::Call
        include Dsl::Error
        include Dsl::ExecutionContext

        using BlockInvocationRefinements # rubocop:disable Sorbet/Refinement core SDK feature

        sig { override.returns(Streams) }
        attr_reader :streams

        sig do
          params(
            operation: SorbetTypes::SourceHash,
            methods: SorbetTypes::SourceHash,
            connection: Connection,
            streams: Streams,
            object_definitions: T.nilable(ObjectDefinitions)
          ).void
        end
        def initialize(operation: {}, methods: {}, connection: Connection.new, streams: ProhibitedStreams.new,
                       object_definitions: nil)
          @operation = T.let(
            Utilities::HashWithIndifferentAccess.wrap(operation),
            ActiveSupport::HashWithIndifferentAccess
          )
          @_methods = T.let(
            Utilities::HashWithIndifferentAccess.wrap(methods),
            ActiveSupport::HashWithIndifferentAccess
          )
          @connection = T.let(connection, Connection)
          @streams = T.let(streams, Streams)
          @object_definitions = T.let(object_definitions, T.nilable(ObjectDefinitions))
        end

        sig do
          params(
            settings: T.nilable(SorbetTypes::SettingsHash),
            input: SorbetTypes::OperationInputHash,
            extended_input_schema: SorbetTypes::OperationSchema,
            extended_output_schema: SorbetTypes::OperationSchema,
            continue: T::Hash[T.any(Symbol, String), T.untyped],
            block: SorbetTypes::OperationExecuteProc
          ).returns(
            T.untyped
          )
        end
        def execute(settings = nil, input = {}, extended_input_schema = [], extended_output_schema = [], continue = {},
                    &block)
          connection.merge_settings!(settings) if settings
          request_or_result = T.unsafe(self).instance_exec(
            connection.settings,
            Utilities::HashWithIndifferentAccess.wrap(input),
            Array.wrap(extended_input_schema).map { |i| Utilities::HashWithIndifferentAccess.wrap(i) },
            Array.wrap(extended_output_schema).map { |i| Utilities::HashWithIndifferentAccess.wrap(i) },
            Utilities::HashWithIndifferentAccess.wrap(continue),
            &block
          )
          result = resolve_request(request_or_result)
          try_convert_to_hash_with_indifferent_access(result)
        end

        sig do
          params(
            settings: T.nilable(SorbetTypes::SettingsHash),
            config_fields: SorbetTypes::OperationInputHash
          ).returns(
            ActiveSupport::HashWithIndifferentAccess
          )
        end
        def extended_schema(settings = nil, config_fields = {})
          object_definitions_hash = object_definitions.lazy(settings, config_fields)
          {
            input: Array.wrap(
              schema_fields(object_definitions_hash, settings, config_fields, &operation[:input_fields])
            ),
            output: schema_fields(object_definitions_hash, settings, config_fields, &operation[:output_fields])
          }.with_indifferent_access
        end

        sig do
          params(
            settings: T.nilable(SorbetTypes::SettingsHash),
            config_fields: SorbetTypes::OperationInputHash
          ).returns(
            SorbetTypes::OperationSchema
          )
        end
        def input_fields(settings = nil, config_fields = {})
          object_definitions_hash = object_definitions.lazy(settings, config_fields)
          Array.wrap(schema_fields(object_definitions_hash, settings, config_fields, &operation[:input_fields]))
        end

        sig do
          params(
            settings: T.nilable(SorbetTypes::SettingsHash),
            config_fields: SorbetTypes::OperationInputHash
          ).returns(
            T.nilable(SorbetTypes::OperationSchema)
          )
        end
        def output_fields(settings = nil, config_fields = {})
          object_definitions_hash = object_definitions.lazy(settings, config_fields)
          T.cast(
            schema_fields(object_definitions_hash, settings, config_fields, &operation[:output_fields]),
            T.nilable(SorbetTypes::OperationSchema)
          )
        end

        sig { params(input: SorbetTypes::OperationInputHash).returns(T.untyped) }
        def summarize_input(input = {})
          summarize(input, operation[:summarize_input])
        end

        sig { params(output: SorbetTypes::OperationInputHash).returns(T.untyped) }
        def summarize_output(output = {})
          summarize(output, operation[:summarize_output])
        end

        sig do
          params(
            settings: T.nilable(SorbetTypes::SettingsHash),
            input: SorbetTypes::OperationInputHash
          ).returns(
            T.untyped
          )
        end
        def sample_output(settings = nil, input = {})
          execute(settings, input, &operation[:sample_output])
        end

        private

        sig { params(input: SorbetTypes::OperationInputHash, schema: Schema).returns(SorbetTypes::OperationInputHash) }
        def apply_input_schema(input, schema)
          input = schema.trim(input)
          schema.apply(input, enforce_required: true) do |value, field|
            field.render_input(value, @_methods[field[:render_input]])
          end
        end

        sig { params(output: SorbetTypes::OperationInputHash, schema: Schema).returns(SorbetTypes::OperationInputHash) }
        def apply_output_schema(output, schema)
          schema.apply(output, enforce_required: false) do |value, field|
            field.parse_output(value, @_methods[field[:parse_output]])
          end
        end

        sig { returns(SorbetTypes::OperationSchema) }
        def config_fields_schema
          operation[:config_fields] || []
        end

        sig { params(data: SorbetTypes::OperationInputHash, paths: T::Array[String]).returns(T.untyped) }
        def summarize(data, paths)
          return data unless paths.present?

          Summarize.new(data: data, paths: paths).call
        end

        sig do
          params(
            object_definitions_hash: ActiveSupport::HashWithIndifferentAccess,
            settings: T.nilable(SorbetTypes::SettingsHash),
            config_fields: SorbetTypes::OperationInputHash,
            schema_proc: T.nilable(SorbetTypes::OperationSchemaProc)
          ).returns(
            T.nilable(T.any(SorbetTypes::OperationSchema, T::Hash[T.any(Symbol, String), T.untyped]))
          )
        end
        def schema_fields(object_definitions_hash, settings, config_fields, &schema_proc)
          return [] unless schema_proc

          Array.wrap(
            execute(settings, config_fields) do |connection, input|
              T.unsafe(self).instance_exec(
                object_definitions_hash,
                connection,
                input,
                &schema_proc
              )
            end
          )
        end

        sig { params(request_or_result: T.untyped).returns(T.untyped) }
        def resolve_request(request_or_result)
          Request.response!(request_or_result)
        end

        sig { params(value: T.untyped).returns(T.untyped) }
        def try_convert_to_hash_with_indifferent_access(value)
          case value
          when ::Hash
            Utilities::HashWithIndifferentAccess.wrap(value)
          when ::Array
            value.map! { |i| try_convert_to_hash_with_indifferent_access(i) }
          else
            value
          end
        end

        sig { returns(ObjectDefinitions) }
        def object_definitions
          T.must(@object_definitions)
        end

        sig { returns(ActiveSupport::HashWithIndifferentAccess) }
        attr_reader :operation

        sig { override.returns(Connection) }
        attr_reader :connection
      end
    end
  end
end
