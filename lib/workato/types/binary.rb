# frozen_string_literal: true

module Workato
  module Types
    class Binary < ::String
      TITLE_LENGTH = 16
      SUMMARY_LENGTH = 128

      def initialize(str)
        super(str)
        force_encoding(Encoding::ASCII_8BIT)
      end

      def to_s
        self
      end

      def to_json(_options = nil)
        summary
      end

      def binary?
        true
      end

      def base64
        Base64.strict_encode64(self)
      end

      def as_string(encoding)
        ::String.new(self, encoding: encoding).encode(encoding, invalid: :replace, undef: :replace)
      end

      def as_utf8
        as_string('utf-8')
      end

      def sha1
        Binary.new(::Digest::SHA1.digest(self))
      end

      private

      def summary
        if length.positive?
          left = "0x#{byteslice(0, SUMMARY_LENGTH).unpack1('H*')}"
          right = bytesize > SUMMARY_LENGTH ? "…(#{bytesize - SUMMARY_LENGTH} bytes more)" : ''
          "#{left}#{right}"
        else
          ''
        end
      end
    end
  end
end
