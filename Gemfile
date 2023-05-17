# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in workato-connector-sdk.gemspec
gemspec

group :development, :test do
  gem 'byebug'
end

group :development do
  gem 'rubocop', require: false
  gem 'rubocop-rspec', require: false
  gem 'rubocop-sorbet', require: false
  gem 'sorbet', require: false
end

group :test do
  gem 'rspec', '~> 3.0'
  gem 'simplecov', require: false
  gem 'simplecov-json', require: false
  gem 'stub_server', '~> 0.6'
  gem 'timecop', '~> 0.9'
  gem 'vcr', '~> 6.0'
  gem 'webmock', '~> 3.0'
end
