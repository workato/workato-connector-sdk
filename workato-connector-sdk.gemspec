# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'workato/connector/sdk/version'

Gem::Specification.new do |spec|
  spec.name          = 'workato-connector-sdk'
  spec.version       = Workato::Connector::Sdk::VERSION
  spec.authors       = ['Pavel Abolmasov']
  spec.email         = ['pavel.abolmasov@workato.com']
  spec.license       = 'MIT'

  spec.summary       = "Gem for running adapter's code outside Workato infrastructure"
  spec.description   = 'Reproduce key concepts of Workato SDK, DSL, behavior and constraints.'
  spec.homepage      = 'https://docs.workato.com/developing-connectors/sdk.html'

  spec.files         = Dir['README.md', 'LICENSE.md', 'lib/**/*', 'exe/workato', 'templates/**/*'] +
                       [
                         'templates/.rspec.erb'
                       ]
  spec.bindir        = 'exe'
  spec.executables   = ['workato']
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.4'

  spec.add_runtime_dependency 'activesupport', '~> 5.2'
  spec.add_runtime_dependency 'countries', '= 1.2.2'
  spec.add_runtime_dependency 'currencies', '= 0.4.2'
  spec.add_runtime_dependency 'gyoku', '= 1.3.1'
  spec.add_runtime_dependency 'jwt', '= 1.5.6'
  spec.add_runtime_dependency 'loofah', '= 2.9.1'
  spec.add_runtime_dependency 'net-http-digest_auth', '= 1.4.0'
  spec.add_runtime_dependency 'nokogiri', '= 1.10.10'
  spec.add_runtime_dependency 'rest-client', '= 2.0.2'
  spec.add_runtime_dependency 'ruby-progressbar', '~> 1.0'
  spec.add_runtime_dependency 'rubyzip', '~> 1.3'
  spec.add_runtime_dependency 'thor', '~> 1.0'

  spec.add_development_dependency 'bundler', '~> 1.17'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'stub_server', '~> 0.4'
  spec.add_development_dependency 'timecop', '~> 0.9'
  spec.add_development_dependency 'vcr', '~> 3.0'
  spec.add_development_dependency 'webmock', '~> 3.0'
end
