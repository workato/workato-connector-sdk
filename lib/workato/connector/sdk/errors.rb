# typed: true
# frozen_string_literal: true

module Workato
  module Connector
    module Sdk
      Error = Class.new(StandardError)

      DetectOnUnauthorizedRequestError = Class.new(Error)

      RuntimeError = Class.new(Error)

      ArgumentError = Class.new(Error)

      ArgumentEncodingError = Class.new(ArgumentError)

      InvalidDefinitionError = Class.new(Error)

      InvalidURIError = Class.new(Error)

      InvalidOutputError = Class.new(Error)

      class InvalidTriggerPollOutputError < InvalidOutputError
        attr_reader :sdk_reference

        def initialize
          @sdk_reference = 'https://docs.workato.com/developing-connectors/sdk/sdk-reference/triggers.html#poll'
          super("Invalid output from trigger poll lambda.\nSee SDK documentation: #{@sdk_reference}")
        end
      end

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

      InvalidMultiAuthDefinition = Class.new(InvalidDefinitionError)

      class UnresolvedMultiAuthOptionError < InvalidMultiAuthDefinition
        attr_reader :name

        def initialize(name)
          super("Cannot find multi-auth definition for '#{name}'")
          @name = name
        end
      end

      class UnresolvedObjectDefinitionError < InvalidDefinitionError
        attr_reader :name

        def initialize(name)
          super("Cannot find object definition for '#{name}'")
          @name = name
        end
      end

      class CircleReferenceObjectDefinitionError < InvalidDefinitionError
        attr_reader :name

        def initialize(name, backtrace = [])
          super("Infinite recursion occurred in object definition for '#{name}'")
          set_backtrace(backtrace)
          @name = name
        end
      end

      RequestError = Class.new(RuntimeError)

      RequestTimeoutError = Class.new(RequestError)

      class RequestFailedError < RequestError
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

      class MissingRequiredInput < RuntimeError
        def initialize(label, toggle_label)
          message = if toggle_label && label != toggle_label
                      "Either '#{label}' or '#{toggle_label}' must be present"
                    else
                      "'#{label}' must be present"
                    end
          super(message)
        end
      end

      RequestTLSCertificateFormatError = Class.new(RequestError)

      RequestPayloadFormatError = Class.new(RequestError)

      JSONRequestFormatError = Class.new(RequestPayloadFormatError)

      JSONResponseFormatError = Class.new(RequestPayloadFormatError)

      XMLRequestFormatError = Class.new(RequestPayloadFormatError)

      XMLResponseFormatError = Class.new(RequestPayloadFormatError)

      WWWFormURLEncodedRequestFormatError = Class.new(RequestPayloadFormatError)

      MultipartFormRequestFormatError = Class.new(RequestPayloadFormatError)

      RAWResponseFormatError = Class.new(RequestPayloadFormatError)

      class UndefinedStdLibMethodError < RuntimeError
        attr_reader :name
        attr_reader :package

        def initialize(name, package)
          @name = name
          @package = package
          super("Undefined method '#{name}' for \"#{package}\" namespace")
        end
      end
    end
  end
end
