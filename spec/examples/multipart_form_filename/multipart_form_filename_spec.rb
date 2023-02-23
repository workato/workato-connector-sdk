# typed: false
# frozen_string_literal: true

RSpec.describe 'multipart with explicit filename' do
  let(:connector) { Workato::Connector::Sdk::Connector.new(connector_code) }

  it 'runs action' do
    stub_request(:post, 'https://httpbin.org/post')
      .with { |request| request.body.include?('filename="lorem.txt"') }
      .to_return(status: 200, body: '{"status":"success"}')

    output = connector.actions.upload.execute

    expect(output).to eq('status' => 'success')
  end

  private

  def connector_code
    @connector_code ||= {
      title: 'multipart form with explicit filename test connector',

      test: lambda do |_connection|
        {}
      end,

      actions: {
        upload: {
          execute: lambda do
            post('https://httpbin.org/post')
              .request_format_multipart_form
              .payload(file_part: ['lorem ipsum', 'text/ascii', 'lorem.txt'])
          end
        }
      }
    }
  end
end
