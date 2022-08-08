# typed: false
# frozen_string_literal: true

module Workato
  module Extension
    module Hash
      def encode_www_form
        ::URI.encode_www_form(self)
      end
    end
  end
end

Hash.include(Workato::Extension::Hash)
