# typed: false
# frozen_string_literal: true

module Workato
  module Extension
    module Object
      # rubocop:disable Naming/PredicateName
      def is_true?(null_true: false)
        if is_a?(::String)
          return true if (self =~ (/\A(true|t|yes|y|1)\Z/i)).present?
          return false if (self =~ (/\A(false|f|no|n|0)\Z/i)).present?
          raise "Can't convert empty string to boolean" if blank?

          raise "Can't convert string value #{self} to boolean"
        elsif is_a?(::Integer)
          return true if self == 1
          return false if zero?

          raise "Can't convert number value #{self} to boolean"
        elsif is_a?(::TrueClass)
          true
        elsif is_a?(::FalseClass)
          false
        elsif is_a?(::NilClass)
          null_true == true
        else
          raise "Can't convert type #{self.class.name} to boolean"
        end
      end

      def is_not_true?(null_not_true: true)
        !is_true?(null_true: !null_not_true)
      end
      # rubocop:enable Naming/PredicateName
    end
  end
end

Object.include(Workato::Extension::Object)
