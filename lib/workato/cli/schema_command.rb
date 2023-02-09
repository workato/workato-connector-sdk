# typed: false
# frozen_string_literal: true

module Workato
  module CLI
    class SchemaCommand
      include Thor::Shell

      SAMPLE_TO_SCHEMA_SUPPORT_TYPES = %w[csv json].freeze
      CSV_SEPARATORS = %w[comma space tab colon semicolon pipe].freeze

      API_GENERATE_SCHEMA_PATH = '/api/sdk/generate_schema'

      def initialize(options:)
        @api_email = options[:api_email] || ENV.fetch(Workato::Connector::Sdk::WORKATO_API_EMAIL_ENV, nil)
        @api_token = options[:api_token] || ENV.fetch(Workato::Connector::Sdk::WORKATO_API_TOKEN_ENV, nil)
        @options = options
      end

      def call
        if verbose?
          say('INPUT')
          say sample[:sample]
        end

        schema = sample_to_schema(sample)

        say('SCHEMA') if verbose?
        jj schema
      end

      private

      attr_reader :options
      attr_reader :api_token
      attr_reader :api_email

      def verbose?
        @options[:verbose]
      end

      def sample
        return @sample if @sample

        @sample = if options[:json]
                    { sample: File.read(options[:json]), type: :json }
                  elsif options[:csv]
                    { sample: File.read(options[:csv]), type: :csv, col_sep: options[:col_sep] }
                  else
                    { sample: {}, type: :json }
                  end
      end

      def sample_to_schema(sample)
        url = "#{Workato::Connector::Sdk::WORKATO_BASE_URL}#{API_GENERATE_SCHEMA_PATH}/#{sample.delete(:type)}"
        response = RestClient.post(
          url,
          sample.to_json,
          {
            content_type: :json,
            accept: :json
          }.merge(auth_headers)
        )
        JSON.parse(response.body)
      rescue RestClient::ExceptionWithResponse => e
        message = JSON.parse(e.response.body).fetch('message') rescue e.message
        raise "Failed to generate schema: #{message}"
      end

      def auth_headers
        if api_email.present?
          warn <<~WARNING
            You are using old authorization schema with --api-email and --api-token which is less secure and deprecated.
            We strongly recommend migrating over to API Clients for authentication to Workato APIs.

            Learn more: https://docs.workato.com/developing-connectors/sdk/cli/reference/cli-commands.html#workato-generate-schema

            If you use API Client token but still see this message, ensure you do not pass --api-email param nor have #{Workato::Connector::Sdk::WORKATO_API_EMAIL_ENV} environment variable set.
          WARNING
          {
            'x-user-email' => api_email,
            'x-user-token' => api_token
          }
        else
          {
            'Authorization' => "Bearer #{api_token}"
          }
        end
      end

      private_constant :API_GENERATE_SCHEMA_PATH
    end
  end
end
