# typed: true
# frozen_string_literal: true

module Workato
  module Connector
    module Sdk
      module Dsl
        module AccountProperty
          def account_property(name)
            AccountProperties.get(name)
          end
        end
      end
    end
  end
end
