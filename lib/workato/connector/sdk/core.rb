# typed: strict
# frozen_string_literal: true

require 'sorbet-runtime'
require 'active_support'
require 'active_support/core_ext/object/deep_dup'
require 'active_support/core_ext/object/try'
require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/array/wrap'
require 'active_support/core_ext/array/access'
require 'active_support/core_ext/numeric/bytes'
require 'active_support/core_ext/numeric/conversions'
require 'active_support/core_ext/numeric/time'

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

require 'workato/utilities/hash_with_indifferent_access'

require_relative 'errors'
require_relative 'account_properties'
require_relative 'operation'
require_relative 'connection'
require_relative 'stream'
require_relative 'streams'
require_relative 'action'
require_relative 'lookup_tables'
require_relative 'object_definitions'
require_relative 'request'
require_relative 'settings'
require_relative 'summarize'
require_relative 'trigger'
require_relative 'version'
require_relative 'workato_schemas'
require_relative 'connector'
