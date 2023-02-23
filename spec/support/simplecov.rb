# typed: false
# frozen_string_literal: true

require 'simplecov'
require 'simplecov-json'
SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new(
  [
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::JSONFormatter
  ]
)
SimpleCov.start do
  # TODO: Add proper test coverage for CLI
  add_filter 'lib/workato/extension/metadata_fix_wrap_kw_args.rb'
  add_filter 'lib/workato/cli/edit_command.rb'
  add_filter 'lib/workato/cli/exec_command.rb'
  add_filter 'lib/workato/cli/generate_command.rb'
  add_filter 'lib/workato/cli/generators/connector_generator.rb'
  add_filter 'lib/workato/cli/generators/master_key_generator.rb'
  add_filter 'lib/workato/cli/main.rb'
  add_filter 'lib/workato/cli/multi_auth_selected_fallback.rb'
  add_filter 'lib/workato/cli/schema_command.rb'
  add_filter 'lib/workato/web/app.rb'

  # TODO: Add proper tests for AWS methods
  add_filter 'lib/workato/connector/sdk/dsl/aws.rb'

  # TODO: Add proper test coverage for Schema
  add_filter 'lib/workato/connector/sdk/schema/type/time.rb'
  add_filter 'lib/workato/connector/sdk/schema/field/convertors.rb'

  # False positive
  add_filter 'lib/workato/connector/sdk.rb'
end
