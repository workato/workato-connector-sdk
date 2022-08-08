# typed: true
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

          def puts(*args)
            T.unsafe(::Kernel).puts(*args)
          end
        end

        class WithDsl
          extend T::Sig

          include Global

          using BlockInvocationRefinements

          sig { params(connection: Connection, args: T.untyped, block: T.untyped).returns(T.untyped) }
          def execute(connection, *args, &block)
            @connection = connection
            T.unsafe(self).instance_exec(*args, &block)
          end

          sig { params(connection: Connection, args: T.untyped, block: T.untyped).returns(T.untyped) }
          def self.execute(connection, *args, &block)
            T.unsafe(WithDsl.new).execute(connection, *args, &block)
          end

          private

          sig { returns(Connection) }
          attr_reader :connection
        end
      end
    end
  end
end
