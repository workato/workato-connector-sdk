# typed: false
# frozen_string_literal: true

module Workato
  module Extension
    module Phone
      def to_phone(options = {})
        ActiveSupport::NumberHelper::NumberToPhoneConverter.convert(self, options).to_s
      end
    end
  end
end

String.include(Workato::Extension::Phone)
Integer.include(Workato::Extension::Phone)
