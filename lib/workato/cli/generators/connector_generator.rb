# typed: false
# frozen_string_literal: true

module Workato
  module CLI
    module Generators
      class ConnectorGenerator < Thor::Group
        include Thor::Actions

        argument :path, type: :string

        def self.source_root
          File.expand_path('../../../../templates', __dir__)
        end

        def create_root
          self.destination_root = path

          empty_directory '.'
          FileUtils.cd(path)
        end

        def create_gemfile
          template('Gemfile.erb', 'Gemfile')
        end

        def create_connector_file
          template('connector.rb.erb', 'connector.rb')
        end

        def create_spec_files
          template('.rspec.erb', '.rspec')

          say(<<~HELP)
            Please select default HTTP mocking behavior suitable for your project?

            1 - secure. Cause an error to be raised for any unknown requests, all request recordings are encrypted.
                        To record a new cassette you need set VCR_RECORD_MODE environment variable

                        Example: VCR_RECORD_MODE=once bundle exec rspec spec/actions/test_action_spec.rb

            2 - simple. Record new interaction if it is a new request, requests are stored as plain text and expose secret tokens.

          HELP

          @vcr_record_mode = ask('Your choice:')

          MasterKeyGenerator.new.call if @vcr_record_mode == '1'

          template('spec/spec_helper.rb.erb', 'spec/spec_helper.rb')
          template('spec/connector_spec.rb.erb', 'spec/connector_spec.rb')
        end

        def bundle_install
          bundle_command('install')
        end

        def show_next_steps
          say <<~HELP
            The new Workato Custom Connector project created at #{path}.

            Now, edit the created file. Add actions, triggers or methods and generate tests for them

            cd #{path} && workato generate test
          HELP
        end

        private

        attr_reader :vcr_record_mode

        def name
          File.basename(path)
        end

        def bundle_command(command)
          say_status :run, "bundle #{command}"

          bundle_command = Gem.bin_path('bundler', 'bundle')

          require 'bundler'
          Bundler.with_original_env do
            exec_bundle_command(bundle_command, command)
          end
        end

        def exec_bundle_command(bundle_command, command)
          full_command = %("#{Gem.ruby}" "#{bundle_command}" #{command})
          if options[:quiet]
            system(full_command, out: File::NULL)
          else
            system(full_command)
          end
        end
      end
    end
  end
end
