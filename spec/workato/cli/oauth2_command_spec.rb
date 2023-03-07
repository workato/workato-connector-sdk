# typed: false
# frozen_string_literal: true

require 'launchy'
require_relative '../../../lib/workato/cli/oauth2_command'

module Workato::CLI
  RSpec.describe OAuth2Command, vcr: { erb: { port: rand(20_000..30_000) } } do
    subject(:oauth2) { described_class.new(options: options).call }

    let(:port) { VCR.current_cassette.erb[:port] }
    let(:options) do
      {
        connector: 'spec/examples/oauth_refresh_automatic/connector.rb',
        settings: 'spec/examples/oauth_refresh_automatic/settings.yaml',
        port: port,
        verbose: true
      }
    end

    let(:fake_callback) do
      retried = false
      Thread.new do
        RestClient.get("http://localhost:#{port}/oauth/callback?code=C-bIt&state=d234a25cecbb7a4e")
      rescue Errno::ECONNRESET
        raise if retried

        sleep(0.5) # wait WEBrick
        retried = true
        retry
      end
    end

    before do
      allow(SecureRandom).to receive(:hex).and_return('d234a25cecbb7a4e')
      allow(Launchy).to(receive(:open)) { fake_callback.join }
    end

    it 'fetches tokens automatically' do
      expect_any_instance_of(Workato::Connector::Sdk::Settings).to receive(:update) do |_instance, new_settings|
        expect(new_settings).to eq({
          access_token: 'ACCT-n6tao7',
          expires_in: '3600',
          refresh_token: 'REFT-oxI6Ik',
          id_token: 'IDT-dfd0Qt',
          state: 'd234a25cecbb7a4e',
          date_of_creation: 1_676_319_722,
          token_type: 'Bearer'
        }.with_indifferent_access)
      end

      stdout = <<~STDOUT
        Local server is running. Allow following redirect_url in your OAuth2 provider:

        http://localhost:#{port}/oauth/callback

             success  Open https://www.example.com/oauth2/authorize?client_id=zXkWHvok&redirect_uri=http%3A%2F%2Flocalhost%3A#{port}%2Foauth%2Fcallback&state=d234a25cecbb7a4e in browser
             success  Receive OAuth2 code=C-bIt
             success  Receive OAuth2 tokens
        {
          "access_token": "ACCT-n6tao7",
          "expires_in": "3600",
          "refresh_token": "REFT-oxI6Ik",
          "id_token": "IDT-dfd0Qt",
          "state": "d234a25cecbb7a4e",
          "date_of_creation": 1676319722,
          "token_type": "Bearer"
        }
             success  Update settings file
      STDOUT
      stderr = <<~STDERR
        [2023-02-13 20:49:26] INFO  WEBrick #{WEBrick::VERSION}
        [2023-02-13 20:49:26] INFO  ruby #{RUBY_VERSION} (#{RUBY_RELEASE_DATE}) [#{RUBY_PLATFORM}]
        [2023-02-13 20:49:26] INFO  WEBrick::HTTPServer#start: pid=#{Process.pid} port=#{port}
        127.0.0.1 - - [13/Feb/2023:20:49:26 UTC] "GET /oauth/callback?code=C-bIt&state=d234a25cecbb7a4e HTTP/1.1" 200 61
        - -> /oauth/callback?code=C-bIt&state=d234a25cecbb7a4e
        127.0.0.1 - - [13/Feb/2023:20:49:26 UTC] "GET /code HTTP/1.1" 200 5
        - -> /code
        [2023-02-13 20:49:26] INFO  going to shutdown ...
        [2023-02-13 20:49:26] INFO  WEBrick::HTTPServer#start done.
      STDERR
      Timecop.freeze('2023-02-13 20:49:26'.to_time) do
        expect { oauth2 }.to output(stdout).to_stdout.and(output(stderr).to_stderr)
      end
    end

    context 'when custom acquire' do
      let(:options) do
        {
          connector: 'spec/examples/oauth_refresh_manual/connector.rb',
          settings: 'spec/examples/oauth_refresh_automatic/settings.yaml',
          port: port,
          verbose: true
        }
      end

      it 'fetches tokens' do
        expect_any_instance_of(Workato::Connector::Sdk::Settings).to receive(:update) do |_instance, new_settings|
          expect(new_settings).to eq({
            access_token: 'ACCT-n6tao7',
            refresh_token: 'REFT-oxI6Ik',
            expired: nil
          }.with_indifferent_access)
        end

        stdout = <<~STDOUT
          Local server is running. Allow following redirect_url in your OAuth2 provider:

          http://localhost:#{port}/oauth/callback

               success  Open https://www.example.com/oauth2/authorize?client_id=zXkWHvok&redirect_uri=http%3A%2F%2Flocalhost%3A#{port}%2Foauth%2Fcallback&response_type=code&state=d234a25cecbb7a4e in browser
               success  Receive OAuth2 code=C-bIt
               success  Receive OAuth2 tokens
          {
            "expired": null,
            "access_token": "ACCT-n6tao7",
            "refresh_token": "REFT-oxI6Ik"
          }
               success  Update settings file
        STDOUT
        stderr = <<~STDERR
          [2023-02-13 20:49:26] INFO  WEBrick #{WEBrick::VERSION}
          [2023-02-13 20:49:26] INFO  ruby #{RUBY_VERSION} (#{RUBY_RELEASE_DATE}) [#{RUBY_PLATFORM}]
          [2023-02-13 20:49:26] INFO  WEBrick::HTTPServer#start: pid=#{Process.pid} port=#{port}
          127.0.0.1 - - [13/Feb/2023:20:49:26 UTC] "GET /oauth/callback?code=C-bIt&state=d234a25cecbb7a4e HTTP/1.1" 200 61
          - -> /oauth/callback?code=C-bIt&state=d234a25cecbb7a4e
          127.0.0.1 - - [13/Feb/2023:20:49:26 UTC] "GET /code HTTP/1.1" 200 5
          - -> /code
          [2023-02-13 20:49:26] INFO  going to shutdown ...
          [2023-02-13 20:49:26] INFO  WEBrick::HTTPServer#start done.
        STDERR
        Timecop.freeze('2023-02-13 20:49:26'.to_time) do
          expect { oauth2 }.to output(stdout).to_stdout.and(output(stderr).to_stderr)
        end
      end
    end

    context 'when non oauth2 connector' do
      let(:options) do
        {
          connector: 'spec/examples/random/connector.rb',
          verbose: true
        }
      end

      it 'fails with error' do
        expect { oauth2 }.to raise_error(/Authorization type is not OAuth2/)
      end
    end
  end
end
