# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'workato-connector-sdk'
  spec.version       = File.read(File.expand_path('VERSION', __dir__)).strip
  spec.authors       = ['Pavel Abolmasov']
  spec.email         = ['pavel.abolmasov@workato.com']
  spec.license       = 'MIT'

  spec.summary       = "Gem for running adapter's code outside Workato infrastructure"
  spec.description   = 'Reproduce key concepts of Workato SDK, DSL, behavior and constraints.'
  spec.homepage      = 'https://www.workato.com/'
  spec.metadata      = {
    'bug_tracker_uri' => 'https://support.workato.com/',
    'documentation_uri' => 'https://docs.workato.com/developing-connectors/sdk/cli.html',
    'homepage_uri' => 'https://www.workato.com/',
    'source_code_uri' => 'https://github.com/workato/workato-connector-sdk',
    'rubygems_mfa_required' => 'true'
  }

  spec.files         = Dir['VERSION', 'README.md', 'LICENSE.md', 'lib/**/*', 'exe/workato', 'templates/**/*'] +
                       [
                         'templates/.rspec.erb',
                         '.yardopts'
                       ]
  spec.bindir        = 'exe'
  spec.executables   = ['workato']
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.7.6'

  spec.add_runtime_dependency 'activesupport', '>= 5.2', '< 7.0'
  spec.add_runtime_dependency 'aws-sigv4', '= 1.2.4'
  spec.add_runtime_dependency 'bundler', '~> 2.0'
  spec.add_runtime_dependency 'charlock_holmes', '= 0.7.7'
  spec.add_runtime_dependency 'em-http-request', '~> 1.0'
  spec.add_runtime_dependency 'gyoku', '= 1.3.1'
  spec.add_runtime_dependency 'i18n', '>= 0.9.5', '< 2.0'
  spec.add_runtime_dependency 'jwt', '>= 1.5.6', '< 3.0'
  spec.add_runtime_dependency 'launchy', '~> 2.0'
  spec.add_runtime_dependency 'net-http-digest_auth', '= 1.4.0'
  spec.add_runtime_dependency 'nokogiri', '>= 1.13.10', '< 1.15'
  spec.add_runtime_dependency 'rack', '~> 2.0'
  spec.add_runtime_dependency 'rails-html-sanitizer', '~> 1.4', '>= 1.4.3'
  spec.add_runtime_dependency 'rest-client', '= 2.1.0'
  spec.add_runtime_dependency 'ruby-progressbar', '~> 1.0'
  spec.add_runtime_dependency 'ruby_rncryptor', '~> 3.0'
  spec.add_runtime_dependency 'rubyzip', '~> 2.3'
  spec.add_runtime_dependency 'sorbet-runtime', '~> 0.5'
  spec.add_runtime_dependency 'thor', '~> 1.0'
  spec.add_runtime_dependency 'webrick', '~> 1.0'

  spec.post_install_message = <<~POST_INSTALL_MESSAGE

    If you updated from workato-connector-sdk prior 1.2.0 your tests could be broken.

    For more details see here:
    https://github.com/workato/workato-connector-sdk/releases/tag/v1.2.0

  POST_INSTALL_MESSAGE
end
