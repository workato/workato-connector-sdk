# typed: false
# frozen_string_literal: true

module Workato
  module Types
    # Explicit wrapper for binary data
    #
    # Workato runtime always converts a String to {Workato::Types::UnicodeString} and
    # binary data to {Workato::Types::Binary} before execute an action.
    #
    # == Call action or trigger by name
    #
    # SDK emulator applies trigger's or action's input/output schema and normalize string when invoke them by name.
    # If you call an operation like this, then emulator passes input with
    # {Workato::Types::UnicodeString} or {Workato::Types::Binary} to the operation
    #
    # CLI
    #   workato exec 'actions.test_action'
    #   workato exec 'triggers.test_poll_trigger'
    #
    # RSpec
    #   connector.actions.test_action.invoke(input)
    #   connector.triggers.test_poll_trigger.invoke(input)
    #
    # == Direct call to execute or poll block
    #
    # Schema is not applied when call an action's execute block directly. For example
    #
    # CLI
    #   workato exec 'actions.test_action.execute'
    #
    # RSpec
    #   connector.actions.test_action.execute(settings, input, input_schema, output_schema)
    #
    # In that case if action's code relies on methods of {Workato::Types::UnicodeString} or {Workato::Types::Binary}
    # then this explicit wrapper should be used for correct behavior.
    #
    # @example
    #   input = {
    #     file_content: Workato::Types::Binary.new(File.read('/path/to/file.bin', 'wb')),
    #     file_name: Workato::Types::UnicodeString.new("Hello World!")
    #   }
    #
    #   connector.actions.upload(settings, input)
    #
    # @see Workato::Types::UnicodeString
    class Binary < ::String
      TITLE_LENGTH = 16
      SUMMARY_LENGTH = 128

      def initialize(str)
        super
        force_encoding(Encoding::ASCII_8BIT)
      end

      def to_s
        self
      end

      def to_json(_options = nil)
        summary
      end

      # Returns true for binary data
      #
      # @return [Boolean]
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
