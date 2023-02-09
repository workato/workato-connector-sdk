# typed: strict
# frozen_string_literal: true

using Workato::Extension::HashWithIndifferentAccess

module Workato
  module Connector
    module Sdk
      module SorbetTypes
        SourceHash = T.type_alias { T.any(HashWithIndifferentAccess, T::Hash[T.any(Symbol, String), T.untyped]) }
      end

      class Connector
        extend T::Sig

        # @api private
        sig { returns(HashWithIndifferentAccess) }
        attr_reader :source

        sig { params(path_to_source_code: String, settings: SorbetTypes::SettingsHash).returns(Connector) }
        def self.from_file(path_to_source_code = DEFAULT_CONNECTOR_PATH, settings = {})
          new(eval(File.read(path_to_source_code), binding, path_to_source_code), settings) # rubocop:disable Security/Eval
        end

        sig { params(definition: SorbetTypes::SourceHash, settings: SorbetTypes::SettingsHash).void }
        def initialize(definition, settings = {})
          @source = T.let(HashWithIndifferentAccess.wrap(definition), HashWithIndifferentAccess)
          @settings = T.let(HashWithIndifferentAccess.wrap(settings), HashWithIndifferentAccess)
          @connection_source = T.let(HashWithIndifferentAccess.wrap(@source[:connection]), HashWithIndifferentAccess)
          @methods_source = T.let(HashWithIndifferentAccess.wrap(@source[:methods]), HashWithIndifferentAccess)
        end

        sig { returns(T.nilable(String)) }
        def title
          @source[:title]
        end

        sig { returns(ActionsProxy) }
        def actions
          @actions = T.let(@actions, T.nilable(ActionsProxy))
          @actions ||= ActionsProxy.new(
            actions: source[:actions].presence || {},
            methods: methods_source,
            object_definitions: object_definitions,
            connection: connection,
            streams: streams
          )
        end

        sig { returns(MethodsProxy) }
        def methods
          @methods = T.let(@methods, T.nilable(MethodsProxy))
          @methods ||= MethodsProxy.new(
            methods: methods_source,
            connection: connection,
            streams: streams
          )
        end

        sig { params(settings: T.nilable(SorbetTypes::SettingsHash)).returns(T.untyped) }
        def test(settings = nil)
          @test = T.let(@test, T.nilable(Action))
          @test ||= Action.new(
            action: {
              execute: source[:test]
            },
            methods: methods_source,
            connection: connection
          )
          @test.execute(settings)
        end

        sig { returns(TriggersProxy) }
        def triggers
          @triggers = T.let(@triggers, T.nilable(TriggersProxy))
          @triggers ||= TriggersProxy.new(
            triggers: source[:triggers].presence || {},
            methods: methods_source,
            connection: connection,
            object_definitions: object_definitions,
            streams: streams
          )
        end

        sig { returns(ObjectDefinitions) }
        def object_definitions
          @object_definitions = T.let(@object_definitions, T.nilable(ObjectDefinitions))
          @object_definitions ||= ObjectDefinitions.new(
            object_definitions: source[:object_definitions].presence || {},
            methods: methods_source,
            connection: connection
          )
        end

        sig { returns(PickListsProxy) }
        def pick_lists
          @pick_lists = T.let(@pick_lists, T.nilable(PickListsProxy))
          @pick_lists ||= PickListsProxy.new(
            pick_lists: source[:pick_lists].presence || {},
            methods: methods_source,
            connection: connection
          )
        end

        sig { returns(Connection) }
        def connection
          @connection = T.let(@connection, T.nilable(Connection))
          @connection ||= Connection.new(
            methods: methods_source,
            connection: connection_source,
            settings: settings
          )
        end

        sig { returns(Streams) }
        def streams
          @streams = T.let(@streams, T.nilable(Streams))
          @streams ||= Streams.new(
            streams: streams_sources,
            methods: methods_source,
            connection: connection
          )
        end

        private

        sig { returns(HashWithIndifferentAccess) }
        def streams_sources
          @streams_sources = T.let(@streams_sources, T.nilable(HashWithIndifferentAccess))
          return @streams_sources if @streams_sources

          @streams_sources = HashWithIndifferentAccess.new
          @streams_sources.merge!(source[:streams].presence || {})
          (source[:actions] || {}).values.map do |action|
            @streams_sources.merge!(action[:streams] || {})
          end
          (source[:trigger] || {}).values.map do |trigger|
            @streams_sources.merge!(trigger[:streams] || {})
          end
          @streams_sources
        end

        sig { returns(HashWithIndifferentAccess) }
        attr_reader :methods_source

        sig { returns(HashWithIndifferentAccess) }
        attr_reader :connection_source

        sig { returns(SorbetTypes::SettingsHash) }
        attr_reader :settings
      end

      class ActionsProxy
        extend T::Sig

        sig do
          params(
            actions: HashWithIndifferentAccess,
            object_definitions: ObjectDefinitions,
            methods: HashWithIndifferentAccess,
            connection: Connection,
            streams: Streams
          ).void
        end
        def initialize(actions:, object_definitions:, methods:, connection:, streams:)
          @methods = methods
          @connection = connection
          @object_definitions = object_definitions
          @streams = streams
          @actions = T.let({}, T::Hash[T.any(Symbol, String), Action])
          define_action_methods(actions)
        end

        sig { params(action: T.any(Symbol, String)).returns(Action) }
        def [](action)
          public_send(action)
        end

        private

        sig { returns(HashWithIndifferentAccess) }
        attr_reader :methods

        sig { returns(Connection) }
        attr_reader :connection

        sig { returns(Streams) }
        attr_reader :streams

        sig { returns(ObjectDefinitions) }
        attr_reader :object_definitions

        sig { params(actions_source: HashWithIndifferentAccess).void }
        def define_action_methods(actions_source)
          actions_source.each do |action, definition|
            define_singleton_method(action) do |input_ = nil|
              @actions[action] ||= Action.new(
                action: definition,
                object_definitions: object_definitions,
                methods: methods,
                connection: connection,
                streams: streams
              )
              return @actions[action] if input_.nil?

              T.must(@actions[action]).invoke(input_)
            end
          end
        end
      end

      private_constant :ActionsProxy

      class MethodsProxy
        extend T::Sig

        sig do
          params(
            methods: HashWithIndifferentAccess,
            connection: Connection,
            streams: Streams
          ).void
        end
        def initialize(methods:, connection:, streams:)
          @methods = methods
          @connection = connection
          @streams = streams
          @actions = T.let({}, T::Hash[T.any(Symbol, String), Action])
          define_action_methods
        end

        private

        sig { returns(HashWithIndifferentAccess) }
        attr_reader :methods

        sig { returns(Connection) }
        attr_reader :connection

        sig { returns(Streams) }
        attr_reader :streams

        sig { void }
        def define_action_methods
          methods.each do |method, _definition|
            define_singleton_method(method) do |*args|
              @actions[method] ||= Action.new(
                action: {
                  execute: -> { T.unsafe(self).call(method, *args) }
                },
                methods: methods,
                connection: connection,
                streams: streams
              )
              T.must(@actions[method]).execute
            end
          end
        end
      end

      private_constant :MethodsProxy

      class PickListsProxy
        extend T::Sig

        sig do
          params(
            pick_lists: HashWithIndifferentAccess,
            methods: HashWithIndifferentAccess,
            connection: Connection
          ).void
        end
        def initialize(pick_lists:, methods:, connection:)
          @methods = methods
          @connection = connection
          @actions = T.let({}, T::Hash[T.any(Symbol, String), Action])
          define_action_methods(pick_lists)
        end

        private

        sig { returns(HashWithIndifferentAccess) }
        attr_reader :methods

        sig { returns(Connection) }
        attr_reader :connection

        sig { params(pick_lists_source: HashWithIndifferentAccess).void }
        def define_action_methods(pick_lists_source)
          pick_lists_source.each do |pick_list, pick_list_proc|
            define_singleton_method(pick_list) do |settings = nil, args = {}|
              @actions[pick_list] ||= Action.new(
                action: {
                  execute: lambda do |connection, input|
                    case pick_list_proc.parameters.length
                    when 0
                      instance_exec(&pick_list_proc)
                    when 1
                      instance_exec(connection, &pick_list_proc)
                    else
                      instance_exec(connection, **input.symbolize_keys, &pick_list_proc)
                    end
                  end
                },
                methods: methods,
                connection: connection
              )
              T.must(@actions[pick_list]).execute(settings, args)
            end
          end
        end
      end

      private_constant :PickListsProxy

      class TriggersProxy
        extend T::Sig

        sig do
          params(
            triggers: HashWithIndifferentAccess,
            object_definitions: ObjectDefinitions,
            methods: HashWithIndifferentAccess,
            connection: Connection,
            streams: Streams
          ).void
        end
        def initialize(triggers:, object_definitions:, methods:, connection:, streams:)
          @methods = methods
          @connection = connection
          @object_definitions = object_definitions
          @streams = streams
          @triggers = T.let({}, T::Hash[T.any(Symbol, String), Trigger])
          define_trigger_methods(triggers)
        end

        sig { params(trigger: T.any(Symbol, String)).returns(Trigger) }
        def [](trigger)
          public_send(trigger)
        end

        private

        sig { returns(HashWithIndifferentAccess) }
        attr_reader :methods

        sig { returns(Connection) }
        attr_reader :connection

        sig { returns(Streams) }
        attr_reader :streams

        sig { returns(ObjectDefinitions) }
        attr_reader :object_definitions

        sig { params(triggers_source: HashWithIndifferentAccess).void }
        def define_trigger_methods(triggers_source)
          triggers_source.each do |trigger, definition|
            define_singleton_method(trigger) do |input_ = nil, payload = {}, headers = {}, params = {}|
              @triggers[trigger] ||= Trigger.new(
                trigger: definition,
                object_definitions: object_definitions,
                methods: methods,
                connection: connection,
                streams: streams
              )

              return @triggers[trigger] if input_.nil?

              T.must(@triggers[trigger]).invoke(input_, payload, headers, params)
            end
          end
        end
      end

      private_constant :TriggersProxy
    end
  end
end
