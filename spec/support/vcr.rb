# typed: false
# frozen_string_literal: true

require 'vcr'
require_relative '../../lib/workato/testing/vcr_multipart_body_matcher'

VCR.configure do |config|
  config.ignore_localhost = true
  config.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  config.hook_into :webmock
  config.register_request_matcher :headers_without_user_agent do |request1, request2|
    request1.headers.except('User-Agent') == request2.headers.except('User-Agent')
  end
  config.register_request_matcher :multipart_body do |request1, request2|
    Workato::Testing::VCRMultipartBodyMatcher.call(request1, request2)
  end
  config.default_cassette_options = {
    record: :once,
    match_requests_on: %i[uri headers_without_user_agent body]
  }
  config.configure_rspec_metadata!
end
