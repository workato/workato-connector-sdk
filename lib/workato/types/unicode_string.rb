# typed: true
# frozen_string_literal: true

module Workato
  module Types
    # Explicit wrapper for unicode strings.
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
    # @see Workato::Types::Binary
    class UnicodeString < ::String
      # @param str Ruby string
      def initialize(str)
        super(str, **{})
        encode!('UTF-8')
      end

      # Returns false for unicode strings
      #
      # @return [Boolean]
      def binary?
        false
      end
    end
  end
end
