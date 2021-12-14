# frozen_string_literal: true

module Workato
  module Connector
    module Sdk
      InvalidDefinitionError = Class.new(StandardError)

      InvalidSchemaError = Class.new(StandardError)

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

      class MissingRequiredInput < StandardError
        def initialize(label, toggle_label)
          message = if toggle_label && label != toggle_label
                      "Either '#{label}' or '#{toggle_label}' must be present"
                    else
                      "'#{label}' must be present"
                    end
          super(message)
        end
      end
    end
  end
end
