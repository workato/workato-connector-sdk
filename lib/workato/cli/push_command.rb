# typed: true
# frozen_string_literal: true

require 'uri'
require 'ruby-progressbar'
require 'zip'
require 'fileutils'
require 'thor'

module Workato
  module CLI
    class PushCommand
      include Thor::Shell

      ENVIRONMENTS = {
        'preview' => 'https://app.preview.workato.com',
        'preview-eu' => 'https://app.preview.eu.workato.com',
        'live' => 'https://app.workato.com',
        'live-eu' => 'https://app.eu.workato.com'
      }.freeze

      API_USER_PATH = '/api/users/me'
      API_IMPORT_PATH = '/api/packages/import'
      API_PACKAGE_PATH = '/api/packages'
      IMPORT_IN_PROGRESS = 'in_progress'

      DEFAULT_LOGO_PATH = 'logo.png'
      DEFAULT_README_PATH = 'README.md'
      PACKAGE_ENTRY_NAME = 'connector.custom_adapter'

      AWAIT_IMPORT_SLEEP_INTERVAL = 15 # seconds
      AWAIT_IMPORT_TIMEOUT_INTERVAL = 120 # seconds

      def initialize(options:)
        @options = options
        @api_base_url = ENVIRONMENTS.fetch(options[:environment]) do
          options[:environment].presence || Workato::Connector::Sdk::WORKATO_BASE_URL
        end
        @api_email = options[:api_email] || ENV.fetch(Workato::Connector::Sdk::WORKATO_API_EMAIL_ENV, nil)
        @api_token = options[:api_token] || ENV.fetch(Workato::Connector::Sdk::WORKATO_API_TOKEN_ENV, nil)
        @folder_id = options[:folder]
      end

      def call
        zip_file_path = build_package
        say_status :success, 'Build package' if verbose?

        import_id = import_package(zip_file_path)
        say_status :success, 'Upload package' if verbose?
        say_status :waiting, 'Process package' if verbose?

        result = await_import(import_id)
        raise human_friendly_error(result) if result.fetch('status') == 'failed'

        say "Connector was successfully uploaded to #{api_base_url}"
      ensure
        FileUtils.rm_f(zip_file_path) if zip_file_path
      end

      private

      attr_reader :options
      attr_reader :api_token
      attr_reader :api_email
      attr_reader :api_base_url

      def verbose?
        @options[:verbose]
      end

      def notes
        options[:notes].presence || loop do
          answer = ask('Please add release notes:')
          break answer if answer.present?
        end
      end

      def build_package
        ::Dir::Tmpname.create(['connector', '.zip']) do |path|
          ::Zip::File.open(path, ::Zip::File::CREATE) do |archive|
            add_connector(archive)
            add_manifest(archive)
            add_logo(archive)
          end
        end
      end

      def add_connector(archive)
        archive.get_output_stream("#{PACKAGE_ENTRY_NAME}.rb") do |f|
          f.write(File.read(options[:connector] || Workato::Connector::Sdk::DEFAULT_CONNECTOR_PATH))
        end
      end

      def add_manifest(archive)
        archive.get_output_stream("#{PACKAGE_ENTRY_NAME}.json") do |f|
          f.write(JSON.pretty_generate(metadata))
        end
      end

      def add_logo(archive)
        return unless logo

        archive.get_output_stream("#{PACKAGE_ENTRY_NAME}#{logo[:extname]}") do |f|
          f.write(logo[:content])
        end
      end

      def import_package(zip_file_path)
        url = "#{api_base_url}#{API_IMPORT_PATH}/#{folder_id}"
        response = RestClient.post(
          url,
          File.open(zip_file_path, 'rb'),
          auth_headers.merge(
            'Content-Type' => 'application/zip'
          )
        )
        JSON.parse(response.body).fetch('id')
      rescue RestClient::NotFound
        raise "Can't find folder with ID=#{folder_id}"
      rescue RestClient::BadRequest => e
        message = JSON.parse(e.response.body).fetch('error')
        raise "Failed to upload connector: #{message}"
      end

      def await_import(import_id)
        url = "#{api_base_url}#{API_PACKAGE_PATH}/#{import_id}"
        Timeout.timeout(AWAIT_IMPORT_TIMEOUT_INTERVAL) do
          loop do
            response = RestClient.get(url, auth_headers)

            json = JSON.parse(response.body)
            break json if json.fetch('status') != IMPORT_IN_PROGRESS

            sleep(AWAIT_IMPORT_SLEEP_INTERVAL)
          end
        end
      rescue Timeout::Error
        raise 'Failed to wait import result. Go to Imports in Workato UI to see the push result'
      end

      def logo
        return @logo if defined?(@logo)

        path = (options.key?(:logo) && options[:logo]) ||
               (File.exist?(DEFAULT_LOGO_PATH) && DEFAULT_LOGO_PATH)
        return @logo = nil unless path

        extname = File.extname(path).downcase
        @logo = {
          extname: extname,
          content: File.read(path),
          content_type: extname == '.png' ? 'image/png' : 'image/jpeg'
        }
      end

      def metadata
        {
          title: title,
          description: description,
          note: notes
        }.tap do |meta|
          if logo
            meta[:logo_file_name] = 'data'
            meta[:logo_content_type] = logo[:content_type]
          end
        end
      end

      def title
        options[:title].presence || connector.title.presence || loop do
          answer = ask('Please provide title of the connector:')
          break answer if answer.present?
        end
      end

      def description
        (options[:description].presence && File.read(options[:description])) ||
          (File.exist?(DEFAULT_README_PATH) && File.read(DEFAULT_README_PATH)) ||
          nil
      end

      def connector
        @connector ||= Workato::Connector::Sdk::Connector.from_file(
          options[:connector] || Workato::Connector::Sdk::DEFAULT_CONNECTOR_PATH
        )
      end

      def auth_headers
        @auth_headers ||=
          if api_email.present?
            warn <<~WARNING
              You are using old authorization schema with --api-email and --api-token which is less secure and deprecated.
              We strongly recommend migrating over to API Clients for authentication to Workato APIs.

              Learn more: https://docs.workato.com/developing-connectors/sdk/cli/reference/cli-commands.html#workato-push

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

      def folder_id
        @folder_id ||=
          begin
            url = "#{api_base_url}#{API_USER_PATH}"
            response = RestClient.get(url, auth_headers)

            json = JSON.parse(response.body)
            json.fetch('root_folder_id').tap do |folder_id|
              say_status :success, "Fetch root folder ID: #{folder_id}" if verbose?
            end
          end
      end

      def human_friendly_error(result)
        result.fetch('error').gsub("#{PACKAGE_ENTRY_NAME}.json: ", '')
      end

      private_constant :IMPORT_IN_PROGRESS,
                       :API_USER_PATH,
                       :API_IMPORT_PATH,
                       :API_PACKAGE_PATH,
                       :PACKAGE_ENTRY_NAME,
                       :AWAIT_IMPORT_SLEEP_INTERVAL,
                       :AWAIT_IMPORT_TIMEOUT_INTERVAL
    end
  end
end
