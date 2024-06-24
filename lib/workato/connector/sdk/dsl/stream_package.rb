# typed: strict
# frozen_string_literal: true

module Workato
  module Connector
    module Sdk
      module Dsl
        class StreamPackage
          extend T::Sig

          sig { params(streams: Streams, connection: Connection).void }
          def initialize(streams:, connection:)
            @streams = streams
            @connection = connection
          end

          sig do
            params(
              stream: T.any(Stream::Proxy, String, T::Hash[T.untyped, T.untyped]),
              from: T.nilable(Integer),
              frame_size: T.nilable(Integer),
              blk: SorbetTypes::StreamInProc
            ).returns(T.untyped)
          end
          def in(stream, from: nil, frame_size: nil, &blk)
            if stream.is_a?(Hash) && stream[:__stream__] && stream[:chunks].nil?
              stream = out(stream[:name], stream[:input] || {})
            end

            Stream.each_chunk(stream: stream, from: from, frame_size: frame_size, &blk)
          end

          sig { params(stream_name: String, input: SorbetTypes::StreamInputHash).returns(Stream::Proxy) }
          def out(stream_name, input = {})
            Stream::Proxy.new(input: Request.response!(input), name: stream_name, stream: streams[stream_name])
          end

          private

          T::Sig::WithoutRuntime.sig { params(symbol: T.any(String, Symbol), _args: T.untyped).void }
          def method_missing(symbol, *_args)
            raise UndefinedStdLibMethodError.new(symbol.to_s, 'workato.stream')
          end

          T::Sig::WithoutRuntime.sig { params(_args: T.untyped).returns(T::Boolean) }
          def respond_to_missing?(*_args)
            false
          end

          sig { returns(Connection) }
          attr_reader :connection

          sig { returns(Streams) }
          attr_reader :streams
        end
      end
    end
  end
end
