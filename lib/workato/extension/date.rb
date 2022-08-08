# typed: false
# frozen_string_literal: true

module Workato
  module Extension
    module Date
      def yweek
        cweek
      end
    end
  end
end

Date.include(Workato::Extension::Date)
DateTime.include(Workato::Extension::Date)
