# typed: false
# frozen_string_literal: true

require 'csv'
require 'singleton'

module Workato
  module Connector
    module Sdk
      class LookupTables
        include Singleton

        def self.from_yaml(path = DEFAULT_LOOKUP_TABLES_PATH)
          instance.load_data(YAML.load_file(path))
        end

        def self.from_csv(table_id, table_name, path)
          rows = CSV.foreach(path, headers: true, return_headers: false).map(&:to_h)
          instance.load_data(table_name => { id: table_id, rows: rows })
        end

        class << self
          delegate :load_data,
                   :lookup,
                   to: :instance
        end

        def lookup(table_name_or_id, *args)
          table = find_table(table_name_or_id)
          return {} unless table

          condition = args.extract_options!
          row = table.lazy.where(condition).first
          return {} unless row

          row.to_hash.with_indifferent_access
        end

        def load_data(data = {})
          @table_by_id ||= {}
          @table_by_name ||= {}
          data.each do |name, table|
            table = Utilities::HashWithIndifferentAccess.wrap(table)
            rows = table['rows'].freeze
            @table_by_id[table['id'].to_i] = rows
            @table_by_name[name] = rows
          end
        end

        private

        def find_table(table_name_or_id)
          unless @table_by_id
            raise 'Lookup Tables are not initialized. ' \
                  'Init data by calling LookupTable.from_file or LookupTable.load_data'
          end

          (table_name_or_id.is_int? && @table_by_id[table_name_or_id.to_i]) || @table_by_name[table_name_or_id]
        end
      end
    end
  end
end
