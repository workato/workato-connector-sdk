# typed: true
# frozen_string_literal: true

module Workato
  module Extension
    module Currency
      class Currencies
        extend T::Sig

        include Singleton

        class << self
          extend T::Sig

          sig { params(value: ::String).returns(T.nilable(Currency)) }
          def find_currency(value)
            instance.find_currency(value)
          end
        end

        class Currency < T::Struct
          const :code, ::String
          const :name, ::String
          const :symbol, T.nilable(::String)
        end

        private_constant :Currency

        def initialize
          @currency_by_code = load_currencies.index_by(&:code).freeze
        end

        sig { params(value: ::String).returns(T.nilable(Currency)) }
        def find_currency(value)
          @currency_by_code[value]
        end

        private

        sig { returns(T::Array[Currency]) }
        def load_currencies
          YAML.load_file(File.expand_path('./currencies.yml', __dir__)).map do |data|
            Currency.new(
              code: data['code'].freeze,
              name: data['name'].freeze,
              symbol: data['symbol']&.freeze
            ).freeze
          end.freeze
        end
      end

      private_constant :Currencies
    end
  end
end
