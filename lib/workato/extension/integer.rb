# typed: true
# frozen_string_literal: true

module Workato
  module Extension
    module Integer
      def is_int? # rubocop:disable Naming/PredicateName
        true
      end

      def to_time
        ::Time.zone.at(self)
      end
    end
  end
end

Integer.include(Workato::Extension::Integer)
