# typed: false
# frozen_string_literal: true

require 'rest-client'

module Workato
  module Extension
    module ContentEncodingDecoder
      module RestClient
        module Response
          def create(body, net_http_res, request, start_time)
            body = decode_content_encoding(net_http_res, body)
            super
          end

          private

          def decode_content_encoding(response, body)
            content_encoding = response['content-encoding']

            case content_encoding&.downcase
            when 'deflate', 'gzip', 'x-gzip'
              response.delete 'content-encoding'
              return body if body.blank?

              deflate_string(body).force_encoding(Encoding.default_external)
            when 'none', 'identity'
              response.delete 'content-encoding'
              body
            else
              body
            end
          end

          def deflate_string(body)
            # Decodes all deflate, gzip or x-gzip
            zstream = Zlib::Inflate.new(Zlib::MAX_WBITS + 32)

            zstream.inflate(body) + zstream.finish
          rescue Zlib::DataError
            # No luck with Zlib decompression. Let's try with raw deflate,
            # like some broken web servers do. This part isn't compatible with Net::HTTP content-decoding
            zstream.close

            zstream = Zlib::Inflate.new(-Zlib::MAX_WBITS)
            zstream.inflate(body) + zstream.finish
          ensure
            zstream.close
          end
        end
      end

      ::RestClient::Response.singleton_class.prepend(RestClient::Response)

      ::RestClient::Request.prepend(
        Module.new do
          def default_headers
            # Should pass this header to be compatible with rest-client 2.0.2 version
            # and rely on decode_content_encoding patch
            # since net/http does not decompress response body if Content-Range is specified
            # (see https://github.com/ruby/ruby/blob/27f6ad737b13062339df0a0c80449cf0dbc92ba5/lib/net/http/response.rb#L254)
            # while the previous version of rest-client does.
            super.tap { |headers| headers[:accept_encoding] = 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3' }
          end
        end
      )
    end
  end
end
