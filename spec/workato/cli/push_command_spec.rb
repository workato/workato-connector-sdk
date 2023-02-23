# typed: false
# frozen_string_literal: true

module Workato::CLI
  RSpec.describe PushCommand, vcr: { match_requests_on: %i[method headers_without_user_agent uri] } do
    subject(:push) { described_class.new(options: options).call }

    let(:options) do
      {
        connector: 'spec/fixtures/connectors/workbot3000.rb',
        logo: 'spec/fixtures/connectors/workbot3000.png',
        api_token: 'ABC-XYZ',
        environment: 'https://app.workato.com',
        notes: 'Test'
      }
    end

    before do
      stub_const('Workato::CLI::PushCommand::AWAIT_IMPORT_SLEEP_INTERVAL', 0.1)
    end

    it 'uploads connector' do
      expect { push }.to output("Connector was successfully uploaded to https://app.workato.com\n").to_stdout
    end

    context 'when legacy auth params' do
      let(:options) do
        {
          connector: 'spec/fixtures/connectors/workbot3000.rb',
          logo: 'spec/fixtures/connectors/workbot3000.png',
          api_email: 'pavel.abolmasov@workato.com',
          api_token: '9be4ac86-21e4-4a50-ae03-427f4b8a7a17',
          environment: 'preview',
          notes: 'Test'
        }
      end

      it 'uploads connector' do
        message = "Connector was successfully uploaded to https://app.preview.workato.com\n"
        warning = <<~WARNING
          You are using old authorization schema with --api-email and --api-token which is less secure and deprecated.
          We strongly recommend migrating over to API Clients for authentication to Workato APIs.

          Learn more: https://docs.workato.com/developing-connectors/sdk/cli/reference/cli-commands.html#workato-push

          If you use API Client token but still see this message, ensure you do not pass --api-email param nor have WORKATO_API_EMAIL environment variable set.
        WARNING
        expect { push }.to output(message).to_stdout.and(output(warning).to_stderr)
      end
    end
  end
end
