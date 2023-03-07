# typed: strict
# frozen_string_literal: true

require 'resolv'

module Workato
  module Connector
    module Sdk
      NetLookupError = Class.new(Error)

      module Dsl
        class NetPackage
          extend T::Sig

          sig { params(name: String, record: String).returns(T::Array[T::Hash[Symbol, T.untyped]]) }
          def lookup(name, record)
            case record.upcase
            when 'A'
              records = dns_resolver.getresources(name, Resolv::DNS::Resource::IN::A)
              records.map { |d| { address: d.address.to_s } }
            when 'SRV'
              records = dns_resolver.getresources(name, Resolv::DNS::Resource::IN::SRV)
              records.map do |d|
                {
                  port: d.port,
                  priority: d.priority,
                  target: d.target.to_s,
                  weight: d.weight
                }
              end
            else
              raise Sdk::ArgumentError, 'Record type not supported, Supported types: "A", "SRV"'
            end
          rescue Resolv::ResolvError, Resolv::ResolvTimeout => e
            raise NetLookupError, e
          end

          private

          sig { returns(Resolv::DNS) }
          def dns_resolver
            @dns_resolver ||= T.let(Resolv::DNS.new, T.nilable(Resolv::DNS))
          end

          T::Sig::WithoutRuntime.sig { params(symbol: T.any(String, Symbol), _args: T.untyped).void }
          def method_missing(symbol, *_args)
            raise UndefinedStdLibMethodError.new(symbol.to_s, 'workato.net')
          end

          T::Sig::WithoutRuntime.sig { params(_args: T.untyped).returns(T::Boolean) }
          def respond_to_missing?(*_args)
            false
          end
        end
      end
    end
  end
end
