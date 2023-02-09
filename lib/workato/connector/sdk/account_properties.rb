# typed: false
# frozen_string_literal: true

require 'csv'
require 'erb'
require 'singleton'

module Workato
  module Connector
    module Sdk
      class AccountProperties
        include Singleton

        def self.from_yaml(path = DEFAULT_ACCOUNT_PROPERTIES_PATH)
          File.open(path) do |f|
            instance.load_data(YAML.safe_load(ERB.new(f.read).result, permitted_classes: [::Symbol]).to_hash)
          end
        end

        def self.from_encrypted_yaml(path = DEFAULT_ENCRYPTED_ACCOUNT_PROPERTIES_PATH, key_path = nil)
          load_data(
            ActiveSupport::EncryptedConfiguration.new(
              config_path: path,
              key_path: key_path || DEFAULT_MASTER_KEY_PATH,
              env_key: DEFAULT_MASTER_KEY_ENV,
              raise_if_missing_key: true
            ).config
          )
        end

        def self.from_csv(path = './account_properties.csv')
          props = CSV.foreach(path, headers: true, return_headers: false).to_h do |row|
            [row[0], row[1]]
          end
          instance.load_data(props)
        end

        class << self
          delegate :load_data,
                   :get,
                   :put,
                   to: :instance
        end

        def get(key)
          @data ||= {}
          @data[key.to_s]
        end

        def put(key, value)
          @data ||= {}
          @data[key.to_s] = value.to_s
        end

        def load_data(props = {})
          props.each { |k, v| put(k, v) }
        end
      end
    end
  end
end
