# typed: false
# frozen_string_literal: true

require_relative 'currency/currencies'
require_relative 'currency/countries'

module Workato
  module Extension
    module Currency
      module NumberToCurrencyConverter
        def to_currency(options = {})
          ActiveSupport::NumberHelper::NumberToCurrencyConverter.convert(self, options)
        end
      end

      module String
        def to_country_alpha2
          to_country&.alpha2.dup
        end

        def to_country_alpha3
          to_country&.alpha3.dup
        end

        def to_country_name
          to_country&.name.dup
        end

        def to_country_number
          to_country&.number.dup
        end

        def to_currency_code
          to_currency_obj&.code.dup
        end

        def to_currency_name
          to_currency_obj&.name.dup
        end

        def to_currency_symbol
          to_currency_obj&.symbol.dup
        end

        def to_state_code(country_name = 'US')
          to_state(country_name)&.first.dup
        end

        def to_state_name(country_name = 'US')
          to_state(country_name)&.last&.name&.upcase # rubocop:disable Style/SafeNavigationChainLength
        end

        private

        def to_country
          Countries.find_country(self)
        end

        def to_state(country_name = 'US')
          country = Countries.find_country(country_name.presence || 'US')
          return nil unless country

          value = upcase
          country.states.find do |code, state|
            code == value || state.name.upcase == value || state.names.any? { |name| name.upcase == value }
          end
        end

        def to_currency_obj
          currency = Currencies.find_currency(upcase)
          return currency if currency

          country_currency_code = to_country&.currency_code&.upcase
          Currencies.find_currency(country_currency_code) if country_currency_code
        end
      end
    end
  end
end

String.include(Workato::Extension::Currency::NumberToCurrencyConverter)
String.include(Workato::Extension::Currency::String)
Integer.include(Workato::Extension::Currency::NumberToCurrencyConverter)
Float.include(Workato::Extension::Currency::NumberToCurrencyConverter)
