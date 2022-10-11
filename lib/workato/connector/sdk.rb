# typed: strict
# frozen_string_literal: true

require 'sorbet-runtime'
::Method.prepend(T::CompatibilityPatches::MethodExtensions)

module Workato
  module Connector
    module Sdk
      DEFAULT_MASTER_KEY_ENV = 'WORKATO_CONNECTOR_MASTER_KEY'
      DEFAULT_MASTER_KEY_PATH = 'master.key'

      DEFAULT_CONNECTOR_PATH = 'connector.rb'

      DEFAULT_SETTINGS_PATH = 'settings.yaml'
      DEFAULT_ENCRYPTED_SETTINGS_PATH = 'settings.yaml.enc'

      DEFAULT_ACCOUNT_PROPERTIES_PATH = 'account_properties.yaml'
      DEFAULT_ENCRYPTED_ACCOUNT_PROPERTIES_PATH = 'account_properties.yaml.enc'

      DEFAULT_LOOKUP_TABLES_PATH = 'lookup_tables.yaml'

      DEFAULT_TIME_ZONE = 'Pacific Time (US & Canada)'

      DEFAULT_SCHEMAS_PATH = 'workato_schemas.json'

      WORKATO_API_EMAIL_ENV = 'WORKATO_API_EMAIL'
      WORKATO_API_TOKEN_ENV = 'WORKATO_API_TOKEN'

      WORKATO_BASE_URL_ENV = 'WORKATO_BASE_URL'
      DEFAULT_WORKATO_BASE_URL = 'https://app.workato.com'
      WORKATO_BASE_URL = T.let(ENV.fetch(WORKATO_BASE_URL_ENV, DEFAULT_WORKATO_BASE_URL), String)
    end
  end
end

# Global libs and monkey patches
require 'active_support/all'
require 'active_support/json'
require_relative '../extension/array'
require_relative '../extension/case_sensitive_headers'
require_relative '../extension/currency'
require_relative '../extension/date'
require_relative '../extension/enumerable'
require_relative '../extension/extra_chain_cert'
require_relative '../extension/hash'
require_relative '../extension/integer'
require_relative '../extension/nil_class'
require_relative '../extension/object'
require_relative '../extension/phone'
require_relative '../extension/string'
require_relative '../extension/symbol'
require_relative '../extension/time'

require_relative './sdk/account_properties'
require_relative './sdk/action'
require_relative './sdk/connection'
require_relative './sdk/connector'
require_relative './sdk/dsl'
require_relative './sdk/errors'
require_relative './sdk/lookup_tables'
require_relative './sdk/object_definitions'
require_relative './sdk/operation'
require_relative './sdk/request'
require_relative './sdk/settings'
require_relative './sdk/summarize'
require_relative './sdk/trigger'
require_relative './sdk/version'
require_relative './sdk/workato_schemas'
require_relative './sdk/xml'
