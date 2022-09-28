# typed: false
# frozen_string_literal: true

module Workato
  module Extension
    module Currency
      def to_currency(options = {})
        ActiveSupport::NumberHelper::NumberToCurrencyConverter.convert(self, options)
      end
    end
  end
end

String.include(Workato::Extension::Currency)
Integer.include(Workato::Extension::Currency)
Float.include(Workato::Extension::Currency)
