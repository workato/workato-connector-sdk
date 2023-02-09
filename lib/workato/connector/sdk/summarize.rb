# typed: true
# frozen_string_literal: true

module Workato
  module Connector
    module Sdk
      class Summarize
        ARRAY_SUMMARIZATION_LIMIT = 100
        STRING_SUMMARIZATION_LIMIT = 1024

        def initialize(data:, paths:)
          @paths = paths
          @data = data
        end

        def call
          return data if paths.blank?

          summarized = data
          paths.each do |path|
            steps = path.split('.')
            if above_summarization_limit?(summarized.dig(*steps))
              summarized = data.deep_dup if summarized.equal?(data)
              apply_summarization_limit(summarized, steps)
            end
          end

          summarized
        end

        private

        attr_reader :data
        attr_reader :paths

        def above_summarization_limit?(candidate)
          (candidate.is_a?(::Array) && candidate.length > ARRAY_SUMMARIZATION_LIMIT) ||
            (candidate.is_a?(::String) && candidate.length > STRING_SUMMARIZATION_LIMIT)
        end

        def apply_summarization_limit(summarized, steps)
          container = if steps.length > 1
                        summarized.dig(*steps[0..-2])
                      else
                        summarized
                      end
          candidate = container[steps.last]
          case candidate
          when Array
            candidate[(ARRAY_SUMMARIZATION_LIMIT - 2)..-2] =
              "... #{candidate.length - ARRAY_SUMMARIZATION_LIMIT} items ..."
          when String
            candidate[(STRING_SUMMARIZATION_LIMIT - 1)..-1] =
              "... #{candidate.length - STRING_SUMMARIZATION_LIMIT} characters ..."
          else
            candidate
          end
        end
      end

      private_constant :Summarize
    end
  end
end
