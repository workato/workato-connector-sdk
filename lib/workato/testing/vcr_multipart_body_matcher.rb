# typed: true
# frozen_string_literal: true

module Workato
  module Testing
    class VCRMultipartBodyMatcher
      MULTIPART_HEADER_MATCHER = %r{^multipart/form-data; boundary=(.+)$}.freeze
      private_constant :MULTIPART_HEADER_MATCHER

      class << self
        def call(request1, request2)
          normalized_multipart_body(request1) == normalized_multipart_body(request2)
        end

        private

        def normalized_multipart_body(request)
          content_type = (request.headers['Content-Type'] || []).first.to_s

          return request.body unless multipart_request?(content_type)

          boundary = MULTIPART_HEADER_MATCHER.match(content_type)[1]
          request.body.gsub(boundary, '----RubyFormBoundaryTsqIBL0iujC5POpr')
        end

        def multipart_request?(content_type)
          return false if content_type.empty?

          MULTIPART_HEADER_MATCHER.match?(content_type)
        end
      end
    end
  end
end
