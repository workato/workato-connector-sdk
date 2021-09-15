# frozen_string_literal: true

require_relative './operation'
require_relative './block_invocation_refinements'

module Workato
  module Connector
    module Sdk
      class Action < Operation
        using BlockInvocationRefinements

        RETRY_DEFAULT_CODES = [429, 500, 502, 503, 504, 507].freeze
        RETRY_DEFAULT_METHODS = %i[get head].freeze
        RETRY_DELAY = 5.seconds
        MAX_RETRIES = 3

        def initialize(action:, connection: {}, methods: {}, settings: {}, object_definitions: nil)
          super(
            operation: action,
            connection: connection,
            methods: methods,
            settings: settings,
            object_definitions: object_definitions
          )

          initialize_retry
        end

        def execute(settings = nil, input = {}, extended_input_schema = [], extended_output_schema = [], &block)
          raise InvalidDefinitionError, "'execute' block is required for action" unless block || action[:execute]

          super(settings, input, extended_input_schema, extended_output_schema, &(block || action[:execute]))
        rescue RequestError => e
          raise e unless retry?(e)

          @retries_left -= 1
          sleep(RETRY_DELAY) && retry
        end

        def checkpoint!(continue:, temp_output: nil)
          raise NotImplementedError
        end

        def reinvoke_after(seconds:, continue:, temp_output: nil)
          raise NotImplementedError
        end

        private

        def retry_on_response
          Array(action[:retry_on_response])
        end

        def retry_on_request
          Array(action[:retry_on_request])
        end

        def max_retries
          action[:max_retries]
        end

        def initialize_retry
          @retries_left = 0
          return if retry_on_response.blank?

          @retry_codes = []
          @retry_matchers = []
          retry_on_response.each { |m| m.is_a?(::Integer) ? @retry_codes << m : @retry_matchers << m }
          @retry_codes = RETRY_DEFAULT_CODES if @retry_codes.empty?
          @retry_methods = (retry_on_request.presence || RETRY_DEFAULT_METHODS).map(&:to_s).map(&:downcase)
          @retries_left = [[max_retries.is_a?(::Integer) && max_retries || MAX_RETRIES, MAX_RETRIES].min, 0].max
        end

        def retry?(exception)
          return unless @retries_left.positive?
          return unless @retry_codes.include?(exception.code.to_i)
          return unless @retry_matchers.empty? || @retry_matchers.any? do |m|
            m === exception.message || m === exception.response
          end

          @retry_methods.include?(exception.method.to_s.downcase)
        end

        alias action operation
      end
    end
  end
end
