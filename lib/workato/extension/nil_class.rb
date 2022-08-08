# typed: true
# frozen_string_literal: true

module Workato
  module Extension
    module NilClass
      def is_int? # rubocop:disable Naming/PredicateName
        false
      end

      def is_number? # rubocop:disable Naming/PredicateName
        false
      end
    end
  end
end

NilClass.include(Workato::Extension::NilClass)
