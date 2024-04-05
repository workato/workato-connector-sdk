# typed: strict
# frozen_string_literal: true

module Workato
  module Connector
    module Sdk
      class Streams
        extend T::Sig

        sig do
          params(
            streams: SorbetTypes::SourceHash,
            methods: SorbetTypes::SourceHash,
            connection: Connection
          ).void
        end
        def initialize(streams: {}, methods: {}, connection: Connection.new)
          @methods_source = methods
          @connection = connection
          @streams = T.let({}, T::Hash[T.any(Symbol, String), Stream])
          @streams_source = streams
          define_action_methods(streams)
        end

        sig { params(stream: T.any(String, Symbol)).returns(Stream) }
        def [](stream)
          @streams[stream] ||= Stream.new(
            stream: @streams_source.fetch(stream),
            methods: methods_source,
            connection: connection
          )
        end

        private

        sig { params(streams_source: SorbetTypes::SourceHash).void }
        def define_action_methods(streams_source)
          streams_source.each_key do |stream|
            define_singleton_method(stream) do |input = {}, from = 0, to = nil, frame_size = Stream::DEFAULT_FRAME_SIZE|
              to ||= from + frame_size
              self[stream].chunk(input, from, to, frame_size)
            end

            define_singleton_method("#{stream}!") do |input = {}, frame_size = Stream::DEFAULT_FRAME_SIZE|
              self[stream].invoke(input, frame_size)
            end
          end
        end

        sig { returns(SorbetTypes::SourceHash) }
        attr_reader :methods_source

        sig { returns(Connection) }
        attr_reader :connection
      end

      # @api private
      class ProhibitedStreams < Streams
        extend T::Sig

        sig { void }
        def initialize
          @streams = Hash.new do
            raise 'Streams are not available in this context. Access streams in actions or triggers'
          end
        end
      end
    end
  end
end
