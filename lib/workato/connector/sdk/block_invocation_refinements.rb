# typed: false
# frozen_string_literal: true

module Workato
  module Connector
    module Sdk
      # match proc's arguments, even if it's a lambda.
      module BlockInvocationRefinements
        module CallRefinement
          def call(*args, &block)
            super(*args.take(parameters.length), &block)
          end
        end

        refine Proc do
          prepend CallRefinement
        end

        module InstanceExecRefinement
          def instance_exec(*args, &block)
            super(*args.take(block.parameters.length), &block)
          end
        end

        refine BasicObject do
          prepend InstanceExecRefinement
        end
      end
    end
  end
end
