# typed: false
# frozen_string_literal: true

require 'delegate'

module Workato
  module Extension
    module Array
      def to_csv(options = {})
        options ||= {}
        multi_line = options[:multi_line]
        multi_line = true if multi_line.nil?
        options = options.dup

        if multi_line && first.is_a?(::Array)
          options[:multi_line] = false
          map { |r| r.to_csv(options) }.join
        else
          options.delete(:multi_line)
          super(**options)
        end
      end

      def ignored(*names)
        reject { |field| names.include?(field[:name]) }
      end

      def only(*names)
        select { |field| names.include?(field[:name]) }
      end

      def required(*names)
        map { |field| names.include?(field[:name]) ? field.merge(optional: false) : field }
      end

      class ArrayWhere < SimpleDelegator
        def initialize(list, options = {})
          @_list = list
          @_operations = []
          @_resolved = false
          where(options || {})
        end

        def where(options = {})
          @_operations << [options] if options.present?
          self
        end

        def not(options = {})
          if options.present?
            where(options)
            @_operations.last << true
          end
          self
        end

        def self.parse_operation(key)
          operation = key.to_s.match(/ *[><=!]={0,1} *\Z/)
          stripped_key, operation = if operation.present?
                                      [operation.pre_match, operation.to_s.strip]
                                    else
                                      [key.to_s, nil]
                                    end
          keys = stripped_key.split_strip_compact('.')
          keys = keys.map(&:to_sym) if key.is_a?(::Symbol)
          [keys, operation]
        end

        def self.coerce_operands(lhs_name, lhs, rhs, operation)
          if operation == 'include?'
            lhs, rhs = rhs, lhs
          end

          if operation.match?(/[><]/) || %w[match? include?].include?(operation)
            raise "The '#{lhs_name}' is nil" if lhs.nil?
            raise "Can't compare '#{lhs_name}' with nil" if rhs.nil?
          end

          if lhs.is_a?(::Numeric) && rhs.try(:is_number?)
            rhs = rhs.is_int? ? rhs.to_i : rhs.to_f
          elsif rhs.is_a?(::Numeric) && lhs.try(:is_number?)
            lhs = lhs.is_int? ? lhs.to_i : lhs.to_f
          end
          [lhs, rhs]
        end

        def self.nested_attr(item, keys)
          keys.reduce(item) do |obj, key|
            obj[key] unless obj.nil?
          end
        end

        def self.match?(operations, item)
          operations.all? do |args, negate|
            result = args.all? do |key, value|
              keys, operation = parse_operation(key)
              compared = nested_attr(item, keys)
              if operation.blank?
                operation = case value
                            when ::Array, Range
                              'include?'
                            when Regexp
                              'match?'
                            else
                              '=='
                            end
              end
              lhs, rhs = coerce_operands(keys.join('.'), compared, value, operation)
              lhs.send(operation, rhs)
            end
            negate ? !result : result
          end
        end

        def __getobj__
          return super if @_resolved

          filtered = @_list.select { |item| self.class.match?(@_operations, item) }
          @_resolved = true
          __setobj__(filtered)
        end
      end
    end
  end
end

Array.prepend(Workato::Extension::Array)
