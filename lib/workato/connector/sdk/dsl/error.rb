# frozen_string_literal: true

module Workato
  module Connector
    module Sdk
      module Dsl
        module Error
          def error(message)
            raise Sdk::RuntimeError, message
          end
        end
      end
    end
  end
end
