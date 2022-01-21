# frozen_string_literal: true

require_relative './block_invocation_refinements'

require_relative './dsl/http'
require_relative './dsl/call'
require_relative './dsl/error'
require_relative './dsl/account_property'
require_relative './dsl/lookup_table'
require_relative './dsl/workato_code_lib'
require_relative './dsl/workato_schema'
require_relative './dsl/time'
require_relative './dsl/aws'

module Workato
  module Connector
    module Sdk
      module Dsl
        module Global
          include Time
          include AccountProperty
          include LookupTable
          include WorkatoCodeLib
          include WorkatoSchema
          include AWS

          def sleep(seconds)
            ::Kernel.sleep(seconds.presence || 0)
          end
        end

        class WithDsl
          include Global

          using BlockInvocationRefinements

          def execute(*args, &block)
            instance_exec(*args, &block)
          end

          def self.execute(*args, &block)
            WithDsl.new.execute(*args, &block)
          end
        end
      end
    end
  end
end
