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
            ssl_ivnames = base.const_get('SSL_IVNAMES', false) # rubocop:disable Sorbet/ConstantsFromStrings
            ssl_ivnames << :@extra_chain_cert unless ssl_ivnames.include?(:@extra_chain_cert)

            ssl_attributes = base.const_get('SSL_ATTRIBUTES', false) # rubocop:disable Sorbet/ConstantsFromStrings
            ssl_attributes << :extra_chain_cert unless ssl_attributes.include?(:extra_chain_cert)
          end
        end
      end

      ::Net::HTTP.include Net::HTTP
    end
  end
end
