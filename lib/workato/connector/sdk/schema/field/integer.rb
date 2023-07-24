# typed: true
# frozen_string_literal: true

require_relative 'convertors'

module Workato
  module Connector
    module Sdk
      class Schema
        module Field
          class Integer < SimpleDelegator
            include Convertors

            DEFAULT_ATTRIBUTES = {
              type: 'integer',
              control_type: 'number',
              parse_output: 'integer_conversion'
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
