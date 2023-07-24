# typed: true
# frozen_string_literal: true

require_relative 'convertors'

module Workato
  module Connector
    module Sdk
      class Schema
        module Field
          class Date < SimpleDelegator
            include Convertors

            DEFAULT_ATTRIBUTES = {
              type: 'date_time',
              control_type: 'date',
              render_input: 'date_conversion',
              parse_output: 'date_conversion'
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
