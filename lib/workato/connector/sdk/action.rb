# typed: strict
# frozen_string_literal: true

require_relative 'operation'
require_relative 'block_invocation_refinements'

module Workato
  module Connector
    module Sdk
      class Action < Operation
        extend T::Sig
        using BlockInvocationRefinements # rubocop:disable Sorbet/Refinement core SDK feature

        include Dsl::ReinvokeAfter

        RETRY_DEFAULT_CODES = T.let([429, 500, 502, 503, 504, 507].freeze, T::Array[Integer])
        RETRY_DEFAULT_METHODS = T.let(%i[get head].freeze, T::Array[Symbol])
        RETRY_DELAY = T.let(5, Integer) # seconds
        RETRY_DELAY_EXP_BASE = T.let(2, Integer)
        MAX_RETRIES = 3

        sig do
          params(
            action: SorbetTypes::SourceHash,
            methods: SorbetTypes::SourceHash,
            connection: Connection,
            object_definitions: T.nilable(ObjectDefinitions),
            streams: Streams
          ).void
        end
        def initialize(action:, methods: {}, connection: Connection.new, object_definitions: nil,
                       streams: ProhibitedStreams.new)
          super(
            operation: action,
            connection: connection,
            methods: methods,
            object_definitions: object_definitions,
            streams: streams
          )

          @retry_delay_factor = T.let(1, Integer)
          @retries_left = T.let(0, Integer)
          @retry_codes = T.let([], T::Array[Integer])
          @retry_methods = T.let([], T::Array[String])
          @retry_matchers = T.let([], T::Array[T.any(Symbol, String, Regexp)])

          initialize_retry
        end

        sig do
          params(
            settings: T.nilable(SorbetTypes::SettingsHash),
            input: SorbetTypes::OperationInputHash,
            extended_input_schema: SorbetTypes::OperationSchema,
            extended_output_schema: SorbetTypes::OperationSchema,
            continue: T::Hash[T.any(Symbol, String), T.untyped],
            block: T.nilable(SorbetTypes::OperationExecuteProc)
          ).returns(
            T.untyped
          )
        end
        def execute(settings = nil, input = {}, extended_input_schema = [], extended_output_schema = [], continue = {},
                    &block)
          raise InvalidDefinitionError, "'execute' block is required for action" unless block || action[:execute]

          loop_reinvoke_after(continue) do |next_continue|
            return super(
              settings,
              input,
              extended_input_schema,
              extended_output_schema,
              next_continue,
              &block || action[:execute]
            )
          end
        rescue RequestFailedError => e
          raise e unless retry?(e)

          @retries_left -= 1
          retry_sleep
          retry
        end

        sig { params(input: SorbetTypes::OperationInputHash).returns(T::Hash[T.any(String, Symbol), T.untyped]) }
        def invoke(input = {})
          extended_schema = extended_schema(nil, input)
          config_schema = Schema.new(schema: config_fields_schema)
          input_schema = Schema.new(schema: extended_schema[:input])
          output_schema = Schema.new(schema: extended_schema[:output])

          input = apply_input_schema(input, config_schema + input_schema)
          output = execute(nil, input, input_schema, output_schema)
          apply_output_schema(output, output_schema)
        end

        private

        sig { returns(T::Array[T.any(Symbol, String, Regexp, Integer)]) }
        def retry_on_response
          Array(action[:retry_on_response])
        end

        sig { returns(T::Array[T.any(Symbol, String, Regexp, Integer)]) }
        def retry_on_request
          Array(action[:retry_on_request])
        end

        sig { returns(T.nilable(Integer)) }
        def max_retries
          action[:max_retries]
        end

        sig { void }
        def initialize_retry
          return if retry_on_response.blank?

          retry_on_response.each { |m| m.is_a?(::Integer) ? @retry_codes << m : @retry_matchers << m }
          @retry_codes = RETRY_DEFAULT_CODES if @retry_codes.empty?
          @retry_methods = (retry_on_request.presence || RETRY_DEFAULT_METHODS).map(&:to_s).map(&:downcase)
          @retries_left = ((max_retries.is_a?(::Integer) && max_retries) || MAX_RETRIES).clamp(0, MAX_RETRIES)
        end

        sig { params(exception: RequestFailedError).returns(T::Boolean) }
        def retry?(exception)
          return false unless @retries_left.positive?
          return false unless @retry_codes.include?(exception.code.to_i)
          return false unless @retry_matchers.empty? || @retry_matchers.any? do |m|
            m === exception.message || m === exception.response
          end

          @retry_methods.include?(exception.method.to_s.downcase)
        end

        sig { void }
        def retry_sleep
          sleep(@retry_delay_factor * RETRY_DELAY)
          @retry_delay_factor *= RETRY_DELAY_EXP_BASE
        end

        alias action operation
      end
    end
  end
end
