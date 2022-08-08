# frozen_string_literal: true

require 'bundler/setup'
require 'workato-connector-sdk'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:all) do
    Workato::Connector::Sdk::Connection.on_settings_update = nil
  end

  require 'webmock/rspec'
  require 'timecop'
  require 'stub_server'
  require_relative './support/vcr'
end
