# typed: true
# frozen_string_literal: true

require_relative 'convertors'

module Workato
  module Connector
    module Sdk
      class Schema
        module Field
          class DateTime < SimpleDelegator
            include Convertors

            DEFAULT_ATTRIBUTES = {
              type: 'date_time',
              control_type: 'date_time',
              render_input: 'date_time_conversion',
              parse_output: 'date_time_conversion'
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
