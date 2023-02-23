# typed: false
# frozen_string_literal: true

require 'rack'
require 'webrick'

RSpec.describe 'patched RestClient to be compatible with v2.0.2' do
  around do |example|
    TestServer.open(9123) do
      example.run
    end
  end

  let(:method) { :get }
  let(:url) { 'http://localhost:9123/zip' }
  let(:host) { 'localhost:9123' }
  let(:response_body) { 'testbinarypayload' }
  let(:before_execution_proc) do
    lambda do |req, _|
      expect(req.to_hash).to eq(
        {
          'accept' => ['*/*'],
          'user-agent' => [RestClient::Platform.default_user_agent],
          'accept-encoding' => ['gzip;q=1.0,deflate;q=0.6,identity;q=0.3'],
          'host' => [host]
        }
      )
      expect(req.instance_variable_get('@decode_content')).to be_falsey
    end
  end

  shared_examples 'regular response' do |emulate_content_encoding:, expected_content_encoding:|
    it "Decodes #{emulate_content_encoding} content-encoding even when content-range header is present in response" do
      response = RestClient::Request.execute(
        method: method,
        url: url + "?emulate_content_encoding=#{emulate_content_encoding}&body=#{response_body}",
        before_execution_proc: before_execution_proc
      )
      expect(response.headers[:content_range]).to be_present
      expect(response.headers[:content_encoding]).to eq(expected_content_encoding)
      expect(response.body).to eq(response_body)
    end
  end

  shared_examples 'raw response' do |emulate_content_encoding:, expected_content_encoding:|
    it "Never decodes #{emulate_content_encoding}" do
      response = RestClient::Request.execute(
        method: method,
        url: url + "?emulate_content_encoding=#{emulate_content_encoding}&body=#{response_body}",
        before_execution_proc: before_execution_proc,
        raw_response: true
      )
      expect(response.headers[:content_range]).to be_present
      expect(response.headers[:content_encoding]).to eq(expected_content_encoding)
      expect(response.body).not_to eq(response_body)
    end
  end

  it_behaves_like 'regular response', emulate_content_encoding: 'gzip', expected_content_encoding: nil
  it_behaves_like 'regular response', emulate_content_encoding: 'deflate', expected_content_encoding: nil
  it_behaves_like 'regular response', emulate_content_encoding: 'raw_deflate', expected_content_encoding: nil

  it_behaves_like 'raw response', emulate_content_encoding: 'gzip', expected_content_encoding: 'gzip'
  it_behaves_like 'raw response', emulate_content_encoding: 'deflate', expected_content_encoding: 'deflate'
  it_behaves_like 'raw response', emulate_content_encoding: 'raw_deflate', expected_content_encoding: 'deflate'
end

class TestServer
  def self.open(port)
    server = new(port)
    server.start
    server.wait
    yield
  ensure
    server.shutdown
  end

  def initialize(port)
    @port = port
    @started = false
    @server = nil
    @thread = nil
  end

  def start
    @thread = Thread.new do
      Rack::Handler::WEBrick.run(
        TestContentEncodingProvider.new,
        Port: @port,
        Logger: WEBrick::Log.new('/dev/null'),
        AccessLog: [],
        DoNotReverseLookup: true,
        StartCallback: -> { @started = true }
      )
    end
  end

  def wait
    Timeout.timeout(10) { sleep 0.1 until @started }
  end

  def shutdown
    Rack::Handler::WEBrick.shutdown
    @thread.join
    return unless WEBrick::Utils::TimeoutHandler.instance.instance_variable_get(:@timeout_info).empty?

    WEBrick::Utils::TimeoutHandler.terminate
  end
end

class TestContentEncodingProvider
  def call(env)
    req = Rack::Request.new(env)
    body_payload = req.params['body']
    case req.params['emulate_content_encoding']
    when 'deflate'
      content_encoding = 'deflate'
      # Zlib::Deflate.deflate(body_payload) is the same, one should be more verbose for reveal
      # the implicit difference between deflate and raw deflate
      zstream = Zlib::Deflate.new(Zlib::DEFAULT_COMPRESSION, Zlib::MAX_WBITS)
      body = zstream.deflate(body_payload, Zlib::FINISH)
      zstream.close
    when 'raw_deflate'
      content_encoding = 'deflate'
      zstream = Zlib::Deflate.new(Zlib::DEFAULT_COMPRESSION, -Zlib::MAX_WBITS)
      body = zstream.deflate(body_payload, Zlib::FINISH)
      zstream.close
    when 'gzip'
      content_encoding = 'gzip'
      body = gzip_string(body_payload)
    else
      body = 'invalid emulate_content_encoding'
    end

    res = Rack::Response.new(env)
    res['Content-Range'] = '0-100/1000'
    res['Content-Encoding'] = content_encoding
    res.status = 206
    res.body = [body]
    res.finish
  end

  private

  def gzip_string(string)
    gzip(string).string
  end

  def gzip(string)
    io = StringIO.new
    io.set_encoding(::Encoding::ASCII_8BIT)
    Zlib::GzipWriter.wrap(io, string.length > 1_000_000 ? Zlib::BEST_COMPRESSION : Zlib::DEFAULT_COMPRESSION) do |gzio|
      gzio.write(string)
      gzio.finish
    end
    io.rewind
    io
  end
end
