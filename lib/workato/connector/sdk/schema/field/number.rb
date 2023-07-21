# typed: true
# frozen_string_literal: true

require_relative 'convertors'

module Workato
  module Connector
    module Sdk
      class Schema
        module Field
          class Number < SimpleDelegator
            include Convertors

            DEFAULT_ATTRIBUTES = {
              type: 'number',
              control_type: 'number',
              parse_output: 'float_conversion'
            }.with_indifferent_access.freeze

            def initialize(field)
              super(DEFAULT_ATTRIBUTES.merge(field))
            end
          end
        end
      end
    end
  end
end
