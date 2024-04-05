# typed: strict
# frozen_string_literal: true

module Workato
  module Connector
    module Sdk
      module SorbetTypes
        SourceHash = T.type_alias do
          T.any(ActiveSupport::HashWithIndifferentAccess, T::Hash[T.any(Symbol, String), T.untyped])
        end
      end

      class Connector
        extend T::Sig

        # @api private
        sig { returns(ActiveSupport::HashWithIndifferentAccess) }
        attr_reader :source

        sig { params(path_to_source_code: String, settings: SorbetTypes::SettingsHash).returns(Connector) }
        def self.from_file(path_to_source_code = DEFAULT_CONNECTOR_PATH, settings = {})
          new(eval(File.read(path_to_source_code), binding, path_to_source_code), settings) # rubocop:disable Security/Eval
        end

        sig { params(definition: SorbetTypes::SourceHash, settings: SorbetTypes::SettingsHash).void }
        def initialize(definition, settings = {})
          @source = T.let(
            Utilities::HashWithIndifferentAccess.wrap(definition),
            ActiveSupport::HashWithIndifferentAccess
          )
          @settings = T.let(
            Utilities::HashWithIndifferentAccess.wrap(settings),
            ActiveSupport::HashWithIndifferentAccess
          )
          @connection_source = T.let(
            Utilities::HashWithIndifferentAccess.wrap(@source[:connection]),
            ActiveSupport::HashWithIndifferentAccess
          )
          @methods_source = T.let(
            Utilities::HashWithIndifferentAccess.wrap(@source[:methods]),
            ActiveSupport::HashWithIndifferentAccess
          )
        end

        sig { returns(T.nilable(String)) }
        def title
          @source[:title]
        end

        sig { returns(ActionsProxy) }
        def actions
          @actions ||= T.let(
            ActionsProxy.new(
              actions: source[:actions].presence || {},
              methods: methods_source,
              object_definitions: object_definitions,
              connection: connection,
              streams: streams
            ),
            T.nilable(ActionsProxy)
          )
        end

        sig { returns(MethodsProxy) }
        def methods
          @methods ||= T.let(
            MethodsProxy.new(
              methods: methods_source,
              connection: connection,
              streams: streams
            ),
            T.nilable(MethodsProxy)
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
          @triggers ||= T.let(
            TriggersProxy.new(
              triggers: source[:triggers].presence || {},
              methods: methods_source,
              connection: connection,
              object_definitions: object_definitions,
              streams: streams
            ),
            T.nilable(TriggersProxy)
          )
        end

        sig { returns(ObjectDefinitions) }
        def object_definitions
          @object_definitions ||= T.let(
            ObjectDefinitions.new(
              object_definitions: source[:object_definitions].presence || {},
              methods: methods_source,
              connection: connection
            ),
            T.nilable(ObjectDefinitions)
          )
        end

        sig { returns(PickListsProxy) }
        def pick_lists
          @pick_lists ||= T.let(
            PickListsProxy.new(
              pick_lists: source[:pick_lists].presence || {},
              methods: methods_source,
              connection: connection
            ),
            T.nilable(PickListsProxy)
          )
        end

        sig { returns(Connection) }
        def connection
          @connection ||= T.let(
            Connection.new(
              methods: methods_source,
              connection: connection_source,
              settings: settings
            ),
            T.nilable(Connection)
          )
        end

        sig { returns(Streams) }
        def streams
          @streams ||= T.let(
            Streams.new(
              streams: streams_sources,
              methods: methods_source,
              connection: connection
            ),
            T.nilable(Streams)
          )
        end

        private

        sig { returns(ActiveSupport::HashWithIndifferentAccess) }
        def streams_sources
          @streams_sources = T.let(@streams_sources, T.nilable(ActiveSupport::HashWithIndifferentAccess))
          return @streams_sources if @streams_sources

          @streams_sources = ActiveSupport::HashWithIndifferentAccess.new
          @streams_sources.merge!(source[:streams].presence || {})
          (source[:actions] || {}).values.map do |action|
            @streams_sources.merge!(action[:streams] || {})
          end
          (source[:trigger] || {}).values.map do |trigger|
            @streams_sources.merge!(trigger[:streams] || {})
          end
          @streams_sources
        end

        sig { returns(ActiveSupport::HashWithIndifferentAccess) }
        attr_reader :methods_source

        sig { returns(ActiveSupport::HashWithIndifferentAccess) }
        attr_reader :connection_source

        sig { returns(SorbetTypes::SettingsHash) }
        attr_reader :settings
      end

      class ActionsProxy
        extend T::Sig

        sig do
          params(
            actions: ActiveSupport::HashWithIndifferentAccess,
            object_definitions: ObjectDefinitions,
            methods: ActiveSupport::HashWithIndifferentAccess,
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

        sig { returns(ActiveSupport::HashWithIndifferentAccess) }
        attr_reader :methods

        sig { returns(Connection) }
        attr_reader :connection

        sig { returns(Streams) }
        attr_reader :streams

        sig { returns(ObjectDefinitions) }
        attr_reader :object_definitions

        sig { params(actions_source: ActiveSupport::HashWithIndifferentAccess).void }
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
            methods: ActiveSupport::HashWithIndifferentAccess,
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

        sig { returns(ActiveSupport::HashWithIndifferentAccess) }
        attr_reader :methods

        sig { returns(Connection) }
        attr_reader :connection

        sig { returns(Streams) }
        attr_reader :streams

        sig { void }
        def define_action_methods
          methods.each_key do |method|
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
            pick_lists: ActiveSupport::HashWithIndifferentAccess,
            methods: ActiveSupport::HashWithIndifferentAccess,
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

        sig { returns(ActiveSupport::HashWithIndifferentAccess) }
        attr_reader :methods

        sig { returns(Connection) }
        attr_reader :connection

        sig { params(pick_lists_source: ActiveSupport::HashWithIndifferentAccess).void }
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
            triggers: ActiveSupport::HashWithIndifferentAccess,
            object_definitions: ObjectDefinitions,
            methods: ActiveSupport::HashWithIndifferentAccess,
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

        sig { returns(ActiveSupport::HashWithIndifferentAccess) }
        attr_reader :methods

        sig { returns(Connection) }
        attr_reader :connection

        sig { returns(Streams) }
        attr_reader :streams

        sig { returns(ObjectDefinitions) }
        attr_reader :object_definitions

        sig { params(triggers_source: ActiveSupport::HashWithIndifferentAccess).void }
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
