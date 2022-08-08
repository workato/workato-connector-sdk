# typed: false
# frozen_string_literal: true

module Workato
  module Connector
    module Sdk
      module Dsl
        module LookupTable
          def lookup(lookup_table_id, *args)
            LookupTables.lookup(lookup_table_id, *args)
          end
        end
      end
    end
  end
end
