# typed: true
# frozen_string_literal: true

require 'charlock_holmes'

module Workato
  module Utilities
    module Encoding
      class << self
        # this function finds first possible encoding that allows to perform correct encoding operations
        # if no encoding is found it preserves initial and replaces bad symbols with ?
        def force_best_encoding!(string)
          original_encoding = string.encoding

          possible_encodings(string).each do |encoding|
            return string.force_encoding(::Encoding::ASCII_8BIT) if encoding.nil? # for binary
            next unless string.force_encoding(encoding).valid_encoding?

            begin
              # try encode to utf
              string.encode(::Encoding::UTF_8)
              return string
            rescue ::Encoding::UndefinedConversionError
              next
            end
          end
          if original_encoding == ::Encoding::BINARY
            string.force_encoding(::Encoding::BINARY)
          else
            string
              .encode!(::Encoding::UTF_8, invalid: :replace, undef: :replace, replace: '?')
              .encode!(original_encoding, invalid: :replace, undef: :replace, replace: '?')
          end
        end

        private

        def possible_encodings(string)
          encoding_candidates = CharlockHolmes::EncodingDetector.detect_all(string).sort! do |a, b|
            confidence_a, encoding_a = a.values_at(:confidence, :ruby_encoding)
            confidence_b, encoding_b = b.values_at(:confidence, :ruby_encoding)
            # If equal and one binary, prefer non-binary.
            if confidence_a == confidence_b
              if encoding_a == 'binary'
                confidence_b += 100
              elsif encoding_b == 'binary'
                confidence_a += 100
              end
            end
            confidence_b <=> confidence_a
          end
          encoding_candidates.map { |candidate| candidate[:ruby_encoding] }
        end
      end
    end
  end
end
