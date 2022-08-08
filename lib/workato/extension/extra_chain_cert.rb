# typed: true
# frozen_string_literal: true

require 'rest-client'
require 'net/http'

module Workato
  module Extension
    module ExtraChainCert
      module Net
        module HTTP
          attr_accessor :extra_chain_cert

          def self.included(base)
            ssl_ivnames = base.const_get('SSL_IVNAMES', false)
            ssl_ivnames << :@extra_chain_cert unless ssl_ivnames.include?(:@extra_chain_cert)

            ssl_attributes = base.const_get('SSL_ATTRIBUTES', false)
            ssl_attributes << :extra_chain_cert unless ssl_attributes.include?(:extra_chain_cert)
          end
        end
      end

      ::Net::HTTP.include Net::HTTP

      module RestClient
        module Request
          attr_accessor :extra_chain_cert

          def net_http_object(hostname, port)
            net = super(hostname, port)
            net.extra_chain_cert = extra_chain_cert if extra_chain_cert
            net
          end
        end
      end

      ::RestClient::Request.prepend RestClient::Request
    end
  end
end
