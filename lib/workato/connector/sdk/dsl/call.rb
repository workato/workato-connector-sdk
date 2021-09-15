# frozen_string_literal: true

module Workato
  module Connector
    module Sdk
      module Dsl
        module Call
          def call(method, *args)
            raise InvalidDefinitionError, "method '#{method}' does not exists" unless @_methods[method]

            instance_exec(*args, &@_methods[method])
          end
        end
      end
    end
  end
end
