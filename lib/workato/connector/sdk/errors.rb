# typed: true
# frozen_string_literal: true

module Workato
  module Connector
    module Sdk
      InvalidDefinitionError = Class.new(StandardError)

      class UnexpectedMethodDefinitionError < InvalidDefinitionError
        attr_reader :name
        attr_reader :definition

        def initialize(name, definition)
          super("Expected lambda for method '#{name}' definition, got: #{definition.class.name}")
          @name = name
          @definition = definition
        end
      end

      class UndefinedMethodError < InvalidDefinitionError
        attr_reader :name

        def initialize(name)
          super("Method '#{name}' does not exists")
          @name = name
        end
      end

      InvalidSchemaError = Class.new(InvalidDefinitionError)

      CustomRequestError = Class.new(StandardError)

      InvalidMultiAuthDefinition = Class.new(InvalidDefinitionError)

      class UnresolvedMultiAuthOptionError < InvalidMultiAuthDefinition
        attr_reader :name

        def initialize(name)
          super("Cannot find multi-auth definition for '#{name}'")
          @name = name
        end
      end

      RuntimeError = Class.new(StandardError)

      class UnresolvedObjectDefinitionError < StandardError
        attr_reader :name

        def initialize(name)
          super("Cannot find object definition for '#{name}'")
          @name = name
        end
      end

      class CircleReferenceObjectDefinitionError < StandardError
        attr_reader :name

        def initialize(name, backtrace = [])
          super("Infinite recursion occurred in object definition for '#{name}'")
          set_backtrace(backtrace)
          @name = name
        end
      end

      class RequestError < StandardError
        attr_reader :method
        attr_reader :code
        attr_reader :response

        def initialize(message:, method:, code:, response:)
          super(message)
          @method = method
          @code = code
          @response = response
        end
      end

      class NotImplementedError < StandardError
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

      RequestTLSCertificateFormatError = Class.new(StandardError)

      RequestPayloadFormatError = Class.new(StandardError)

      JSONRequestFormatError = Class.new(RequestPayloadFormatError)

      JSONResponseFormatError = Class.new(RequestPayloadFormatError)

      XMLRequestFormatError = Class.new(RequestPayloadFormatError)

      XMLResponseFormatError = Class.new(RequestPayloadFormatError)

      WWWFormURLEncodedRequestFormatError = Class.new(RequestPayloadFormatError)

      MultipartFormRequestFormatError = Class.new(RequestPayloadFormatError)

      RAWResponseFormatError = Class.new(RequestPayloadFormatError)
    end
  end
end
