# typed: false
# frozen_string_literal: true

module Workato
  module Extension
    module Symbol
      def labelize(*acronyms)
        to_s.labelize(*acronyms)
      end
    end
  end
end

Symbol.include(Workato::Extension::Symbol)
