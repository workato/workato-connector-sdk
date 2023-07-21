# typed: true
# frozen_string_literal: true

require_relative 'block_invocation_refinements'

require_relative 'dsl/http'
require_relative 'dsl/call'
require_relative 'dsl/reinvoke_after'
require_relative 'dsl/error'
require_relative 'dsl/account_property'
require_relative 'dsl/lookup_table'
require_relative 'dsl/workato_package'
require_relative 'dsl/workato_schema'
require_relative 'dsl/time'
require_relative 'dsl/aws'
require_relative 'dsl/execution_context'

module Workato
  module Connector
    module Sdk
      module Dsl
        module Global
          extend T::Sig
          extend T::Helpers

          abstract!

          # @api private
          sig { abstract.returns(Streams) }
          def streams; end

          # @api private
          sig { abstract.returns(Connection) }
          def connection; end

          include Time
          include AccountProperty
          include LookupTable
          include WorkatoSchema

          delegate :parse_json,
                   :uuid,
                   to: :workato

          def workato
            @workato ||= WorkatoPackage.new(streams: streams, connection: connection)
          end

          def sleep(seconds)
            ::Kernel.sleep(seconds.presence || 0)
          end

          def puts(*args)
            T.unsafe(::Kernel).puts(*args)
          end

          def encrypt(text, key)
            ::Kernel.require('ruby_rncryptor')

            enc_text = ::RubyRNCryptor.encrypt(text, key)
            ::Base64.strict_encode64(enc_text)
          end

          def decrypt(text, key)
            ::Kernel.require('ruby_rncryptor')

            text = ::Base64.decode64(text)
            dec_text = ::RubyRNCryptor.decrypt(text, key)
            Workato::Types::Binary.new(dec_text)
          rescue Exception => e # rubocop:disable Lint/RescueException
            message = e.message.to_s
            case message
            when /Password may be incorrect/
              ::Kernel.raise 'invalid/corrupt input or key'
            when /RubyRNCryptor only decrypts version/
              ::Kernel.raise 'invalid/corrupt input'
            else
              ::Kernel.raise
            end
          end

          def blank
            ''
          end

          def clear; end

          def null; end

          def skip; end
        end

        class WithDsl
          extend T::Sig

          include Global

          using BlockInvocationRefinements

          sig { params(connection: Connection, streams: Streams).void }
          def initialize(connection = Connection.new, streams = ProhibitedStreams.new)
            @connection = connection
            @streams = streams
          end

          def execute(...)
            T.unsafe(self).instance_exec(...)
          end

          private

          sig { override.returns(Connection) }
          attr_reader :connection

          sig { override.returns(Streams) }
          attr_reader :streams
        end
      end
    end
  end
end
