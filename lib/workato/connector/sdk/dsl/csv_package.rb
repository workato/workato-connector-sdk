# typed: strict
# frozen_string_literal: true

require 'csv'

module Workato
  module Connector
    module Sdk
      CsvError = Class.new(Sdk::Error)

      CsvFormatError = Class.new(CsvError)

      class CsvFileTooBigError < CsvError
        extend T::Sig

        sig { returns(Integer) }
        attr_reader :size

        sig { returns(Integer) }
        attr_reader :max

        sig { params(size: Integer, max: Integer).void }
        def initialize(size, max)
          super("CSV file is too big. Max allowed: #{max.to_s(:human_size)}, got: #{size.to_s(:human_size)}")
          @size = T.let(size, Integer)
          @max = T.let(max, Integer)
        end
      end

      class CsvFileTooManyLinesError < CsvError
        extend T::Sig

        sig { returns(Integer) }
        attr_reader :max

        sig { params(max: Integer).void }
        def initialize(max)
          super("CSV file has too many lines. Max allowed: #{max}")
          @max = T.let(max, Integer)
        end
      end

      module Dsl
        class CsvPackage
          extend T::Sig

          MAX_FILE_SIZE_FOR_PARSE = T.let(30.megabytes, Integer)
          private_constant :MAX_FILE_SIZE_FOR_PARSE

          MAX_LINES_FOR_PARSE = 65_000
          private_constant :MAX_LINES_FOR_PARSE

          sig do
            params(
              str: String,
              headers: T.any(T::Boolean, T::Array[String], String),
              col_sep: T.nilable(String),
              row_sep: T.nilable(String),
              quote_char: T.nilable(String),
              skip_blanks: T.nilable(T::Boolean),
              skip_first_line: T::Boolean
            ).returns(
              T::Array[T::Hash[String, T.untyped]]
            )
          end
          def parse(str, headers:, col_sep: nil, row_sep: nil, quote_char: nil, skip_blanks: nil,
                    skip_first_line: false)
            if headers.is_a?(FalseClass)
              raise Sdk::ArgumentError,
                    'Headers are required. ' \
                    'Pass headers: true to implicitly use the first line or array/string for explicit headers'

            end

            if str.bytesize > MAX_FILE_SIZE_FOR_PARSE
              raise CsvFileTooBigError.new(str.bytesize, MAX_FILE_SIZE_FOR_PARSE)
            end

            index = 0
            options = { col_sep: col_sep, row_sep: row_sep, quote_char: quote_char, headers: headers,
                        skip_blanks: skip_blanks }.compact
            Enumerator.new do |consumer|
              CSV.parse(str, **options) do |row|
                if index.zero? && skip_first_line
                  index += 1
                  next
                end
                if index == MAX_LINES_FOR_PARSE
                  raise CsvFileTooManyLinesError, MAX_LINES_FOR_PARSE
                end

                index += 1
                consumer.yield(T.cast(row, CSV::Row).to_hash)
              end
            end.to_a
          rescue CSV::MalformedCSVError => e
            raise CsvFormatError, e
          rescue ::ArgumentError => e
            raise Sdk::ArgumentError, e.message
          end

          sig do
            params(
              str: T.nilable(String),
              headers: T.nilable(T::Array[String]),
              col_sep: T.nilable(String),
              row_sep: T.nilable(String),
              quote_char: T.nilable(String),
              force_quotes: T.nilable(T::Boolean),
              blk: T.proc.params(csv: CSV).void
            ).returns(
              String
            )
          end
          def generate(str = nil, headers: nil, col_sep: nil, row_sep: nil, quote_char: nil, force_quotes: nil, &blk)
            options = { col_sep: col_sep, row_sep: row_sep, quote_char: quote_char, headers: headers,
                        force_quotes: force_quotes }.compact
            options[:write_headers] = options[:headers].present?

            ::CSV.generate(str || String.new, **options, &blk)
          rescue ::ArgumentError => e
            raise Sdk::ArgumentError, e.message
          end

          private

          T::Sig::WithoutRuntime.sig { params(symbol: T.any(String, Symbol), _args: T.untyped).void }
          def method_missing(symbol, *_args)
            raise UndefinedStdLibMethodError.new(symbol.to_s, 'workato.csv')
          end

          T::Sig::WithoutRuntime.sig { params(_args: T.untyped).returns(T::Boolean) }
          def respond_to_missing?(*_args)
            false
          end
        end
      end
    end
  end
end
