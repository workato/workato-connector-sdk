# typed: true
# frozen_string_literal: true

require 'active_support/encrypted_configuration'

require_relative '../extension/metadata_fix_wrap_kw_args'

module Workato
  module CLI
    class EditCommand
      def initialize(path:, options:)
        @encrypted_file_path = path
        @key_path = options[:key] || Workato::Connector::Sdk::DEFAULT_MASTER_KEY_PATH
        @encrypted_config ||= ActiveSupport::EncryptedConfiguration.new(
          config_path: encrypted_file_path,
          key_path: @key_path,
          env_key: Workato::Connector::Sdk::DEFAULT_MASTER_KEY_ENV,
          raise_if_missing_key: false
        )
      end

      def call
        ensure_editor_available || return
        ensure_encryption_key_present

        catch_editing_exceptions do
          encrypted_config.change do |tmp_path|
            system("#{ENV.fetch('EDITOR', nil)} #{tmp_path}")
          end
        end

        puts 'File encrypted and saved.'
      rescue ActiveSupport::MessageEncryptor::InvalidMessage
        raise "Couldn't decrypt #{encrypted_file_path}. Perhaps you passed the wrong key?"
      end

      private

      attr_reader :key_path
      attr_reader :encrypted_file_path
      attr_reader :encrypted_config

      def ensure_encryption_key_present
        return if encrypted_config.key.present?

        Generators::MasterKeyGenerator.new.call(@key_path)
      end

      def ensure_editor_available
        return true if ENV['EDITOR'].to_s.present?

        puts <<~HELP
          No $EDITOR to open file in. Assign one like this:

          EDITOR="mate --wait" workato edit #{encrypted_file_path}

          For editors that fork and exit immediately, it's important to pass a wait flag,
          otherwise the credentials will be saved immediately with no chance to edit.

        HELP

        false
      end

      def catch_editing_exceptions
        yield
      rescue Interrupt
        puts 'Aborted changing file: nothing saved.'
      end
    end
  end
end
