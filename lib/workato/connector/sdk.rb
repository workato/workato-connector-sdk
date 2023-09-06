# typed: strict
# frozen_string_literal: true

require 'sorbet-runtime'

# Global libs and monkey patches
require 'active_support/all'
require 'active_support/json'

require_relative '../types/binary'
require_relative '../types/unicode_string'

require_relative '../extension/array'
require_relative '../extension/case_sensitive_headers'
require_relative '../extension/content_encoding_decoder'
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

require_relative 'sdk/core'

begin
  tz = ENV.fetch('TZ', nil)
  if tz.present? && tz != 'UTC'
    warn "WARNING: TZ environment variable is set to '#{tz}'. Set TZ=UTC for consistency with Workato platform'"
  else
    ENV['TZ'] = 'UTC'
  end
  Time.zone = Workato::Connector::Sdk::DEFAULT_TIME_ZONE
rescue TZInfo::DataSourceNotFound
  puts ''
  puts "tzinfo-data is not present. Please install gem 'tzinfo-data' by 'gem install tzinfo-data'"
  puts ''
  exit!
end
