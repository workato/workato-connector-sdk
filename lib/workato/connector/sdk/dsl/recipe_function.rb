# typed: false
# frozen_string_literal: true

module Workato
  module Connector
    module Sdk
      module Dsl
        module RecipeFunction
          def call_by_name(name, *args)
            puts "Function called #{name}"
          end
        end
      end
    end
  end
end
