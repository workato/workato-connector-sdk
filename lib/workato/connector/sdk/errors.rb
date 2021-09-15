# frozen_string_literal: true

module Workato
  module Connector
    module Sdk
      InvalidDefinitionError = Class.new(StandardError)

      CustomRequestError = Class.new(StandardError)

      class RequestError < StandardError
        attr_reader :method,
                    :code,
                    :response

        def initialize(message:, method:, code:, response:)
          super(message)
          @method = method
          @code = code
          @response = response
        end
      end

      class NotImplementedError < RuntimeError
        def initialize(msg = 'This part of Connector SDK is not implemented in workato-connector-sdk yet')
          super
        end
      end
    end
  end
end
