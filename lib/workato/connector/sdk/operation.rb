# typed: strict
# frozen_string_literal: true

require_relative './dsl'
require_relative './block_invocation_refinements'
require_relative './schema'

using Workato::Extension::HashWithIndifferentAccess

module Workato
  module Connector
    module Sdk
      module SorbetTypes
        OperationInputHash = T.type_alias { T::Hash[T.any(Symbol, String), T.untyped] }

        OperationExecuteProc = T.type_alias do
          T.proc.params(
            arg0: HashWithIndifferentAccess,
            arg1: HashWithIndifferentAccess,
            arg2: T.any(Schema, T::Array[HashWithIndifferentAccess]),
            arg3: T.any(Schema, T::Array[HashWithIndifferentAccess]),
            arg4: HashWithIndifferentAccess
          ).returns(
            T.untyped
          )
        end

        OperationSchema = T.type_alias do
          T.any(Schema, T::Array[T::Hash[T.any(Symbol, String), T.untyped]])
        end

        OperationSchemaProc = T.type_alias do
          T.proc.params(
            arg0: HashWithIndifferentAccess,
            arg1: HashWithIndifferentAccess,
            arg2: HashWithIndifferentAccess
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

        using BlockInvocationRefinements

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
          @operation = T.let(HashWithIndifferentAccess.wrap(operation), HashWithIndifferentAccess)
          @_methods = T.let(HashWithIndifferentAccess.wrap(methods), HashWithIndifferentAccess)
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
            HashWithIndifferentAccess.wrap(input),
            Array.wrap(extended_input_schema).map { |i| HashWithIndifferentAccess.wrap(i) },
            Array.wrap(extended_output_schema).map { |i| HashWithIndifferentAccess.wrap(i) },
            HashWithIndifferentAccess.wrap(continue),
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
            HashWithIndifferentAccess
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
            object_definitions_hash: HashWithIndifferentAccess,
            settings: T.nilable(SorbetTypes::SettingsHash),
            config_fields: SorbetTypes::OperationInputHash,
            schema_proc: T.nilable(SorbetTypes::OperationSchemaProc)
          ).returns(
            T.nilable(T.any(SorbetTypes::OperationSchema, T::Hash[T.any(Symbol, String), T.untyped]))
          )
        end
        def schema_fields(object_definitions_hash, settings, config_fields, &schema_proc)
          return [] unless schema_proc

          execute(settings, config_fields) do |connection, input|
            T.unsafe(self).instance_exec(
              object_definitions_hash,
              connection,
              input,
              &schema_proc
            )
          end
        end

        sig { params(request_or_result: T.untyped).returns(T.untyped) }
        def resolve_request(request_or_result)
          case request_or_result
          when Request
            resolve_request(request_or_result.response!)
          when ::Array
            request_or_result.each_with_index.inject(request_or_result) do |acc, (item, index)|
              response_item = resolve_request(item)
              if response_item.equal?(item)
                acc
              else
                (acc == request_or_result ? acc.dup : acc).tap { |a| a[index] = response_item }
              end
            end
          when ::Hash
            request_or_result.inject(request_or_result) do |acc, (key, value)|
              response_value = resolve_request(value)
              if response_value.equal?(value)
                acc
              else
                (acc == request_or_result ? acc.dup : acc).tap { |h| h[key] = response_value }
              end
            end
          else
            request_or_result
          end
        end

        sig { params(value: T.untyped).returns(T.untyped) }
        def try_convert_to_hash_with_indifferent_access(value)
          case value
          when ::Hash
            HashWithIndifferentAccess.wrap(value)
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

        sig { returns(HashWithIndifferentAccess) }
        attr_reader :operation

        sig { override.returns(Connection) }
        attr_reader :connection
      end
    end
  end
end
