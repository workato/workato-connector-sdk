# frozen_string_literal: true

module Workato
  module Connector
    module Sdk
      class Connector
        attr_reader :source

        def self.from_file(path_to_source_code = DEFAULT_CONNECTOR_PATH, settings = {})
          new(eval(File.read(path_to_source_code), binding, path_to_source_code), settings) # rubocop:disable Security/Eval
        end

        def initialize(definition, settings = {})
          @source = definition.with_indifferent_access
          @settings = settings.with_indifferent_access
          @connection_source = @source[:connection] || {}
          @methods_source = @source[:methods] || {}
        end

        def title
          @source[:title]
        end

        def actions
          @actions ||= ActionsProxy.new(
            actions: source[:actions].presence || {},
            methods: methods_source,
            object_definitions: object_definitions,
            connection: connection,
            settings: settings
          )
        end

        def methods
          @methods ||= MethodsProxy.new(
            methods: methods_source,
            connection: connection,
            settings: settings
          )
        end

        def test(settings = nil)
          @test ||= Action.new(
            action: {
              execute: source[:test]
            },
            methods: methods_source,
            connection: connection,
            settings: send(:settings)
          ).execute(settings)
        end

        def triggers
          @triggers ||= TriggersProxy.new(
            triggers: source[:triggers].presence || {},
            methods: methods_source,
            connection: connection,
            object_definitions: object_definitions,
            settings: settings
          )
        end

        def object_definitions
          @object_definitions ||= ObjectDefinitions.new(
            object_definitions: source[:object_definitions].presence || {},
            methods: methods_source,
            connection: connection,
            settings: settings
          )
        end

        def pick_lists
          @pick_lists ||= PickListsProxy.new(
            pick_lists: source[:pick_lists].presence || {},
            methods: methods_source,
            connection: connection,
            settings: settings
          )
        end

        def connection
          @connection ||= Connection.new(
            methods: methods_source,
            connection: connection_source,
            settings: settings
          )
        end

        private

        attr_reader :methods_source,
                    :connection_source,
                    :settings
      end

      class ActionsProxy
        def initialize(actions:, object_definitions:, methods:, connection:, settings:)
          @methods = methods
          @connection = connection
          @object_definitions = object_definitions
          @settings = settings
          define_action_methods(actions)
        end

        def [](action)
          public_send(action)
        end

        private

        attr_reader :methods,
                    :connection,
                    :object_definitions,
                    :settings

        def define_action_methods(actions)
          actions.each do |action, definition|
            define_singleton_method(action) do |input_ = nil|
              @actions ||= {}
              @actions[action] ||= Action.new(
                action: definition,
                object_definitions: object_definitions,
                methods: methods,
                connection: connection,
                settings: settings
              )
              return @actions[action] if input_.nil?

              @actions[action].invoke(input_)
            end
          end
        end
      end

      class MethodsProxy
        def initialize(methods:, connection:, settings:)
          @methods = methods
          @connection = connection
          @settings = settings
          define_action_methods
        end

        private

        attr_reader :methods,
                    :connection,
                    :settings

        def define_action_methods
          methods.each do |method, _definition|
            define_singleton_method(method) do |*args|
              @actions ||= {}
              @actions[method] ||= Action.new(
                action: {
                  execute: -> { call(method, *args) }
                },
                methods: methods,
                connection: connection,
                settings: settings
              )
              @actions[method].execute
            end
          end
        end
      end

      class PickListsProxy
        def initialize(pick_lists:, methods:, connection:, settings:)
          @methods = methods
          @connection = connection
          @settings = settings
          define_action_methods(pick_lists)
        end

        private

        attr_reader :methods,
                    :connection,
                    :settings

        def define_action_methods(pick_lists)
          pick_lists.each do |pick_list, pick_list_proc|
            define_singleton_method(pick_list) do |settings = nil, args = {}|
              @actions ||= {}
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
                connection: connection,
                settings: send(:settings)
              )
              @actions[pick_list].execute(settings, args)
            end
          end
        end
      end

      class TriggersProxy
        def initialize(triggers:, object_definitions:, methods:, connection:, settings:)
          @methods = methods
          @connection = connection
          @object_definitions = object_definitions
          @settings = settings
          @triggers = {}
          define_trigger_methods(triggers)
        end

        private

        attr_reader :methods,
                    :connection,
                    :object_definitions,
                    :settings

        def define_trigger_methods(triggers)
          triggers.each do |trigger, definition|
            define_singleton_method(trigger) do |input_ = nil, payload = {}, headers = {}, params = {}|
              @triggers[trigger] ||= Trigger.new(
                trigger: definition,
                object_definitions: object_definitions,
                methods: methods,
                connection: connection,
                settings: settings
              )

              return @triggers[trigger] if input_.nil?

              @triggers[trigger].invoke(input_, payload, headers, params)
            end
          end
        end
      end
    end
  end
end
