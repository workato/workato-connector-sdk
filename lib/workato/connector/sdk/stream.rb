# typed: strict
# frozen_string_literal: true

module Workato
  module Connector
    module Sdk
      module SorbetTypes
        StreamProc = T.type_alias do
          T.proc.params(
            input: SorbetTypes::StreamInputHash,
            from: Integer,
            to: Integer,
            frame_size: Integer
          ).returns(SorbetTypes::StreamOutput)
        end

        StreamInProc = T.type_alias do
          T.proc.params(
            data: T.untyped,
            from: Integer,
            to: T.nilable(Integer),
            eof: T::Boolean,
            next_from: T.nilable(Integer)
          ).void
        end

        StreamInputHash = T.type_alias { T::Hash[T.any(Symbol, String), T.untyped] }

        StreamOutput = T.type_alias { [T.untyped, T::Boolean] }
      end

      class Stream < Operation
        extend T::Sig

        DEFAULT_FRAME_SIZE = T.let(10.megabytes, Integer)

        using BlockInvocationRefinements # rubocop:disable Sorbet/Refinement core SDK feature
        include Dsl::ReinvokeAfter

        sig do
          params(
            stream: SorbetTypes::StreamProc,
            methods: SorbetTypes::SourceHash,
            connection: Connection
          ).void
        end
        def initialize(stream:, methods: {}, connection: Connection.new)
          super(methods: methods, connection: connection)
          @stream_proc = stream
        end

        sig do
          params(
            input: SorbetTypes::StreamInputHash,
            from: Integer,
            to: Integer,
            frame_size: Integer
          ).returns(SorbetTypes::StreamOutput)
        end
        def chunk(input = {}, from = 0, to = from + DEFAULT_FRAME_SIZE, frame_size = DEFAULT_FRAME_SIZE)
          raise "'frame_size' must be a positive integer number" unless frame_size.positive?

          stream_proc = @stream_proc
          execute(nil, { input: input, from: from, to: to, size: frame_size }) do |_, input| # rubocop:disable Lint/ShadowingOuterLocalVariable
            T.unsafe(self).instance_exec(input['input'], input['from'], input['to'], input['size'], &stream_proc)
          end
        end

        sig { params(input: SorbetTypes::StreamInputHash, frame_size: Integer).returns(T.untyped) }
        def invoke(input = {}, frame_size = DEFAULT_FRAME_SIZE)
          proxy = Proxy.new(name: '', input: input, stream: self)
          reader = Reader.new(stream: proxy, frame_size: frame_size)
          data = T.let(nil, T.untyped)
          reader.each_chunk do |chunk|
            data = data.nil? ? chunk : data + chunk
          end
          data
        end

        class << self
          extend T::Sig

          sig do
            params(
              stream: T.any(Proxy, T::Hash[T.untyped, T.untyped], String),
              from: T.nilable(Integer),
              frame_size: T.nilable(Integer),
              blk: SorbetTypes::StreamInProc
            ).void
          end
          def each_chunk(stream:, from:, frame_size: nil, &blk)
            Reader.new(stream: stream, from: from, frame_size: frame_size).each_chunk(&blk)
          end
        end

        class Reader
          extend T::Sig

          ProxyReadProc = T.type_alias do
            T.proc.params(
              data: T.untyped,
              from: Integer,
              eof: T::Boolean,
              next_from: T.nilable(Integer)
            ).void
          end

          sig do
            params(
              stream: T.any(Proxy, T::Hash[T.untyped, T.untyped], String),
              from: T.nilable(Integer),
              frame_size: T.nilable(Integer)
            ).void
          end
          def initialize(stream:, from: nil, frame_size: nil)
            @stream = T.let(
              stream.is_a?(Hash) && stream[:__stream__] ? from_mock(stream) : stream,
              T.any(Proxy, Mock, T::Hash[T.untyped, T.untyped], String)
            )
            @from = T.let(from || 0, Integer)
            @frame_size = T.let(frame_size || DEFAULT_FRAME_SIZE, Integer)
          end

          sig { params(_blk: SorbetTypes::StreamInProc).void }
          def each_chunk(&_blk)
            case @stream
            when Proxy, Mock
              @stream.read(from: @from, frame_size: @frame_size) do |chunk, from, eof, next_from|
                yield(chunk, from, calculate_byte_to(chunk, from), eof, next_from)
              end
            when Hash
              chunk = @stream[:data][@from..]
              yield(chunk, @from, calculate_byte_to(chunk, @from), @stream[:eof], nil)
            else
              chunk = @stream[@from..]
              yield(@stream[@from..], @from, calculate_byte_to(chunk, @from), true, nil)
            end
          end

          private

          sig { params(chunk: T.untyped, from: Integer).returns(T.nilable(Integer)) }
          def calculate_byte_to(chunk, from)
            (chunk_size = chunk.try(:bytesize) || 0).zero? ? nil : from + chunk_size - 1
          end

          sig { params(hash: T::Hash[T.untyped, T.untyped]).returns(T.any(Proxy, Mock)) }
          def from_mock(hash)
            case hash[:chunks]
            when Proc
              Proxy.new(
                name: hash[:name],
                input: Utilities::HashWithIndifferentAccess.wrap(hash[:input] || {}),
                stream: Stream.new(
                  stream: hash[:chunks],
                  connection: Connection.new(
                    connection: hash[:connection] || {},
                    settings: hash[:settings] || {}
                  )
                )
              )
            when Hash
              Mock.new(chunks: hash[:chunks])
            else
              raise 'Mock streams with Proc or Hash. Read spec/examples/stream/connector_spec.rb for examples'
            end
          end
        end

        private_constant :Reader

        # @api private
        class Proxy
          extend T::Sig

          sig { params(name: String, input: SorbetTypes::StreamInputHash, stream: Stream).void }
          def initialize(name:, input:, stream:)
            @name = name
            @input = input
            @stream = stream
          end

          sig { params(_options: T.untyped).returns(T::Hash[String, T.untyped]) }
          def as_json(_options = nil)
            {
              __stream__: true,
              name: name,
              input: input
            }
          end

          sig { params(from: Integer, frame_size: Integer, _blk: Reader::ProxyReadProc).void }
          def read(from:, frame_size:, &_blk)
            next_from = from
            loop do
              res = read_chunk(next_from, frame_size)
              yield(res.data, res.from, res.eof, res.next_from)
              break if res.eof

              next_from = T.must(res.next_from)
            end
          end

          private

          sig { returns(String) }
          attr_reader :name

          sig { returns(SorbetTypes::StreamInputHash) }
          attr_reader :input

          class Chunk < T::Struct
            const :data, T.untyped # rubocop:disable Sorbet/ForbidUntypedStructProps
            const :from, Integer
            const :eof, T::Boolean
            const :next_from, T.nilable(Integer)
          end
          private_constant :Chunk

          sig { params(from: Integer, frame_size: Integer).returns(Chunk) }
          def read_chunk(from, frame_size)
            data, eof = @stream.chunk(input, from, from + frame_size - 1, frame_size)
            next_from = from + (data&.length || 0)
            next_from = nil if eof
            Chunk.new(data: data, from: from, eof: eof, next_from: next_from)
          end
        end

        class Mock
          extend T::Sig

          sig { params(chunks: T::Hash[T.any(Integer, String), T.untyped]).void }
          def initialize(chunks:)
            @chunks = T.let(chunks.transform_keys(&:to_i), T::Hash[Integer, T.untyped])
          end

          sig { params(from: Integer, frame_size: Integer, _blk: Reader::ProxyReadProc).void }
          def read(from:, frame_size:, &_blk)
            last_from = chunks.keys.last
            chunks.each do |chunk_from, data|
              next if chunk_from < from

              eof = chunk_from == last_from
              next_from = eof ? nil : chunk_from + frame_size

              yield(data, chunk_from, eof, next_from)
            end
          end

          private

          sig { returns(T.untyped) }
          attr_reader :chunks
        end

        private_constant :Mock
      end
    end
  end
end
