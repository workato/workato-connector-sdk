# typed: true
# frozen_string_literal: true

require 'json'

module Workato
  module Connector
    module Sdk
      class WorkatoSchemas
        include Singleton

        class << self
          def from_json(path = DEFAULT_SCHEMAS_PATH)
            load_data(JSON.parse(File.read(path)))
          end

          delegate :find,
                   :load_data,
                   to: :instance
        end

        def load_data(data)
          @schemas_by_id ||= {}.with_indifferent_access
          @schemas_by_id.merge!(data.stringify_keys)
        end

        def find(id)
          unless @schemas_by_id
            raise 'Workato Schemas are not initialized. ' \
                  'Init data by calling WorkatoSchemas.from_json or WorkatoSchemas.load_data'
          end

          @schemas_by_id.fetch(id.to_s)
        end
      end
    end
  end
end
