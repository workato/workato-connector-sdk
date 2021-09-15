# frozen_string_literal: true

require 'rest-client'
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

      module RestClient
        module Request
          attr_accessor :case_sensitive_headers

          def processed_headers
            return @processed_headers if case_sensitive_headers.blank?
            return case_sensitive_headers if @processed_headers.blank?

            @processed_headers.merge(case_sensitive_headers)
          end

          def execute(&block)
            # With 2.0.0+, net/http accepts URI objects in requests and handles wrapping
            # IPv6 addresses in [] for use in the Host request header.
            net_http_request = net_http_request_class(method).new(uri, processed_headers)
            net_http_request.case_sensitive_headers = case_sensitive_headers
            transmit(uri, net_http_request, payload, &block)
          ensure
            payload&.close
          end
        end
      end

      ::RestClient::Request.prepend RestClient::Request
    end
  end
end
