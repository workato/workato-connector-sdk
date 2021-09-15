# frozen_string_literal: true

module Workato
  module Connector
    module Sdk
      module Dsl
        # https://docs.workato.com/developing-connectors/sdk/sdk-reference/http.html#http-methods
        module HTTP
          def get(url, params = {})
            http_request(url, method: 'GET').params(params).response_format_json
          end

          def options(url, params = {})
            http_request(url, method: 'OPTIONS').params(params).response_format_json
          end

          def head(url, params = {})
            http_request(url, method: 'HEAD').params(params).response_format_json
          end

          def post(url, payload = nil)
            http_request(url, method: 'POST').payload(payload).format_json
          end

          def patch(url, payload = nil)
            http_request(url, method: 'PATCH').payload(payload).format_json
          end

          def put(url, payload = nil)
            http_request(url, method: 'PUT').payload(payload).format_json
          end

          def delete(url, payload = nil)
            http_request(url, method: 'DELETE').payload(payload).format_json
          end

          def copy(url, payload = nil)
            http_request(url, method: 'COPY').payload(payload).format_json
          end

          def move(url, payload = nil)
            http_request(url, method: 'MOVE').payload(payload).format_json
          end

          private

          def http_request(url, method:)
            Request.new(
              url,
              method: method,
              connection: connection,
              settings: settings,
              action: self
            )
          end
        end
      end
    end
  end
end
