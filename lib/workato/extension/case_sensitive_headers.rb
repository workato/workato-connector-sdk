# typed: false
# frozen_string_literal: true

require 'net/http'

module Workato
  module Extension
    module CaseSensitiveHeaders
      module Net
        module HTTPHeader
          attr_accessor :case_sensitive_headers

          def capitalize(modified_name)
            return super if case_sensitive_headers.blank?

            original_name = case_sensitive_headers.keys.find { |name| name.downcase == modified_name }
            original_name.presence || super
          end
        end
      end

      ::Net::HTTPHeader.prepend Net::HTTPHeader
      ::Net::HTTPGenericRequest.prepend Net::HTTPHeader
    end
  end
end
