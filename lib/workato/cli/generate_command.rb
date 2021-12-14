# frozen_string_literal: true

module Workato
  module CLI
    class GenerateCommand < Thor
      include Thor::Actions

      TEST_TYPES = %w[trigger action pick_list object_definition method].freeze

      def self.source_root
        File.expand_path('../../../templates', __dir__)
      end

      desc 'test', 'Generate empty test for connector'

      method_option :connector, type: :string, aliases: '-c', desc: 'Path to connector source code',
                                lazy_default: Workato::Connector::Sdk::DEFAULT_CONNECTOR_PATH
      method_option :action, type: :string, aliases: '-a', desc: 'Create test for Action with name'
      method_option :trigger, type: :string, aliases: '-t', desc: 'Create test for Trigger with name'
      method_option :pick_list, type: :string, aliases: '-p', desc: 'Create test for Pick List with name'
      method_option :object_definition, type: :string, aliases: '-o',
                                        desc: 'Create test for Object Definition with name'
      method_option :method, type: :string, aliases: '-m', desc: 'Create test for Method with name'

      long_desc <<~HELP
        The 'workato generate test' command analyzes existing connector source and creates an empty test for
        all connector's definitions.

        Example:

          workato generate test # This generates a skeletal tests for all connector's definitions.

          workato generate test --action=test_action # This generates an empty test for `test_action` only.

          workato generate test --method=some_method
      HELP

      def test
        create_spec_files
      end

      desc 'schema', 'Generate schema by JSON example'
      def schema
        say <<~HELP
          Generate schema is not implemented yet.
          Use Workato UI "JSON to Schema" converter for now.
        HELP
      end

      private

      def create_spec_files
        definitions = options.slice(*TEST_TYPES)
        if definitions.any?
          definitions.each do |type, name|
            create_spec_file(type, name)
          end
        else
          ensure_connector_source

          template('spec/connector_spec.rb.erb', 'spec/connector_spec.rb', skip: true)
          TEST_TYPES.each do |type|
            (connector.source[type.pluralize] || {}).each do |(name, _definition)|
              create_spec_file(type, name)
            end
          end
        end
      end

      def ensure_connector_source
        return if connector

        raise "Can't find connector source code"
      end

      def create_spec_file(type, name)
        template(
          partial(type),
          "spec/#{type}s/#{sanitized_filename(name)}_spec.rb",
          context: binding,
          skip: true
        )
      end

      def connector
        return @connector if @connector

        @connector = Workato::Connector::Sdk::Connector.from_file(
          options[:connector] || Workato::Connector::Sdk::DEFAULT_CONNECTOR_PATH
        )
      rescue StandardError
        nil
      end

      def partial(type)
        "spec/#{type.downcase}_spec.rb.erb"
      end

      def sanitized_filename(name)
        name.downcase.gsub(/[^0-9A-z.\-]/, '_')
      end
    end
  end
end
