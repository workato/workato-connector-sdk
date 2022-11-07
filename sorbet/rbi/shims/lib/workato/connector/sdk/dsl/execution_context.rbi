# typed: strict
# frozen_string_literal: true

module Workato
  module Connector
    module Sdk
      module Dsl
        module ExecutionContext
          sig { returns(String) }
          def recipe_id; end
        end
      end
    end
  end
end
