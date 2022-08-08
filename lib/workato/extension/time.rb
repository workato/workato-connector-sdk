# typed: false
# frozen_string_literal: true

module Workato
  module Extension
    module Time
      def yweek
        to_date.cweek
      end
    end
  end
end

Time.include(Workato::Extension::Time)
