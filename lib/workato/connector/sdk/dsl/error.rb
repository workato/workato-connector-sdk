# typed: false
# frozen_string_literal: true

module Workato
  module Connector
    module Sdk
      module Dsl
        module Error
          # @param message [String]
          # @raise [Workato::Connector::Sdk::RuntimeError]
          def error(message)
            raise Sdk::RuntimeError, message
          end
        end
      end
    end
  end
end
