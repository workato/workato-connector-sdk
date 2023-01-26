# typed: false
# frozen_string_literal: true

module Workato
  module Connector
    module Sdk
      module Dsl
        module Call
          ruby2_keywords def call(method, *args)
            method_proc = @_methods[method]

            raise UndefinedMethodError, method unless method_proc
            raise UnexpectedMethodDefinitionError.new(method, method_proc) unless method_proc.is_a?(Proc)

            instance_exec(*args, &method_proc)
          end
        end
      end
    end
  end
end
