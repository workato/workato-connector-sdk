# typed: false
# frozen_string_literal: true

module Workato
  module Connector
    module Sdk
      module Dsl
        # https://docs.workato.com/developing-connectors/sdk/sdk-reference/http.html#http-methods
        module HTTP
          PARALLEL_SUCCESS_INDEX = 0
          private_constant :PARALLEL_SUCCESS_INDEX

          PARALLEL_RESULTS_INDEX = 1
          private_constant :PARALLEL_RESULTS_INDEX

          PARALLEL_ERRORS_INDEX = 2
          private_constant :PARALLEL_ERRORS_INDEX

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

          def parallel(requests = [], threads: 1, rpm: nil, requests_per_period: nil, period: 1.minute.to_i) # rubocop:disable Lint/UnusedMethodArgument
            requests.each.with_object([true, [], []]) do |request, result|
              response = nil
              exception = nil
              begin
                response = request.response!
              rescue StandardError => e
                exception = e.to_s
              end
              result[PARALLEL_SUCCESS_INDEX] &&= exception.nil?
              result[PARALLEL_RESULTS_INDEX] << response
              result[PARALLEL_ERRORS_INDEX] << exception
            end
          end

          private

          def http_request(url, method:)
            Request.new(url, method: method, connection: connection, action: self)
          end
        end
      end
    end
  end
end
