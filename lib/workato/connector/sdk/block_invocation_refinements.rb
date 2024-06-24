# typed: false
# frozen_string_literal: true

module Workato
  module Connector
    module Sdk
      # Match proc's arguments, even if it's a lambda.
      # @api private
      module BlockInvocationRefinements
        refine Proc do
          def call(*args, &block)
            super(*args.take(parameters.length), &block)
          end
        end

        refine BasicObject do
          ruby2_keywords def instance_exec(*args, &block)
            super(*args.take(block.parameters.length), &block)
          end
        end
      end
    end
  end
end
