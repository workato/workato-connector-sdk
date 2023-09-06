# typed: false
# frozen_string_literal: true

require 'active_support/encrypted_configuration'

module Workato
  module Connector
    module Sdk
      module SorbetTypes
        SettingsHash = T.type_alias do
          T.any(ActiveSupport::HashWithIndifferentAccess, T::Hash[T.any(Symbol, String), T.untyped])
        end
      end

      class Settings
        class << self
          def from_file(path = DEFAULT_SETTINGS_PATH, name = nil)
            new(path: path, name: name, encrypted: false).read
          end

          def from_encrypted_file(path = DEFAULT_ENCRYPTED_SETTINGS_PATH, key_path = nil, name = nil)
            new(path: path, name: name, key_path: key_path, encrypted: true).read
          end

          def from_default_file(name = nil)
            new(name: name).read
          end
        end

        def initialize(path: nil, encrypted: nil, name: nil, key_path: nil)
          @path = path
          @name = name
          @key_path = key_path
          @encrypted = encrypted
        end

        def read
          if path.nil?
            if File.exist?(DEFAULT_ENCRYPTED_SETTINGS_PATH)
              @encrypted = true
              @path = DEFAULT_ENCRYPTED_SETTINGS_PATH
              read_encrypted_file
            elsif File.exist?(DEFAULT_SETTINGS_PATH)
              @encrypted = false
              @path = DEFAULT_SETTINGS_PATH
              read_plain_file
            else
              @encrypted = false
              {}
            end
          elsif encrypted.nil?
            begin
              @encrypted = false
              read_plain_file
            rescue KeyError
              raise
            rescue StandardError
              @encrypted = true
              read_encrypted_file
            end
          elsif encrypted
            read_encrypted_file
          else
            read_plain_file
          end
        end

        def update(new_settings)
          if encrypted
            update_encrypted_file(new_settings)
          else
            update_plain_file(new_settings)
          end
        end

        private

        attr_reader :key_path
        attr_reader :name
        attr_reader :path
        attr_reader :encrypted

        def read_plain_file
          all_settings = File.open(path) do |f|
            YAML.safe_load(f.read, permitted_classes: [::Symbol]).to_hash.with_indifferent_access
          end

          (name ? all_settings.fetch(name) : all_settings) || {}
        end

        def update_plain_file(new_settings)
          @path ||= DEFAULT_SETTINGS_PATH
          File.write(path, YAML.dump({})) unless File.exist?(path)

          all_settings = self.class.from_file(path)

          merge_settings(all_settings, new_settings)

          File.write(path, serialize(all_settings))
        end

        def read_encrypted_file
          all_settings = Utilities::HashWithIndifferentAccess.wrap(encrypted_configuration.config)

          (name ? all_settings.fetch(name) : all_settings) || {}
        end

        def update_encrypted_file(new_settings)
          all_settings = Utilities::HashWithIndifferentAccess.wrap(encrypted_configuration.config)

          merge_settings(all_settings, new_settings)

          encrypted_configuration.write(serialize(all_settings))
        end

        def merge_settings(all_settings, new_settings)
          if name
            all_settings[name] ||= {}
            all_settings[name].merge!(new_settings)
          else
            all_settings.merge!(new_settings)
          end
        end

        def encrypted_configuration
          @encrypted_configuration ||= FixedEncryptedConfiguration.new(
            config_path: path,
            key_path: key_path || DEFAULT_MASTER_KEY_PATH,
            env_key: DEFAULT_MASTER_KEY_ENV,
            raise_if_missing_key: true
          )
        end

        def serialize(settings)
          YAML.dump(settings.to_hash)
        end
      end

      class FixedEncryptedConfiguration < ActiveSupport::EncryptedConfiguration
        private

        def handle_missing_key
          # Original methods incorectly passes constructor params
          raise MissingKeyError.new(key_path: key_path, env_key: env_key) if raise_if_missing_key
        end
      end

      private_constant :FixedEncryptedConfiguration
    end
  end
end
