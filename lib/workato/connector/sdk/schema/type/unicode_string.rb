# frozen_string_literal: true

module Workato
  module Connector
    module Sdk
      class Schema
        module Type
          class UnicodeString < ::String
            def initialize(str)
              super(str, {})
              encode!('UTF-8')
            end

            def binary?
              false
            end
          end
        end
      end
    end
  end
end
