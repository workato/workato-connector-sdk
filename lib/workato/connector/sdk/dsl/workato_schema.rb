# typed: true
# frozen_string_literal: true

module Workato
  module Connector
    module Sdk
      module Dsl
        module WorkatoSchema
          def workato_schema(id)
            WorkatoSchemas.find(id)
          end
        end
      end
    end
  end
end
