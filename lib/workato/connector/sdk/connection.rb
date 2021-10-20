# frozen_string_literal: true

require_relative './block_invocation_refinements'

module Workato
  module Connector
    module Sdk
      class Connection
        using BlockInvocationRefinements

        attr_reader :source

        def initialize(connection: {}, methods: {}, settings: {})
          @methods_source = methods.with_indifferent_access
          @source = connection.with_indifferent_access
          @settings = settings
        end

        def authorization
          @authorization ||= Authorization.new(
            connection: source,
            methods: methods_source,
            settings: @settings
          )
        end

        def base_uri(settings = {})
          source[:base_uri]&.call(settings.with_indifferent_access)
        end

        private

        attr_reader :methods_source

        class Authorization
          attr_reader :source

          def initialize(connection: {}, methods: {}, settings: {})
            @connection_source = connection.with_indifferent_access
            @source = (connection[:authorization] || {}).with_indifferent_access
            @methods_source = methods.with_indifferent_access
            @settings = settings
          end

          def token_url?
            source[:token_url].present?
          end

          def acquire?
            source[:acquire].present?
          end

          def refresh?
            source[:refresh].present?
          end

          def type
            source[:type]
          end

          def refresh_on
            Array.wrap(source[:refresh_on]).compact
          end

          def detect_on
            Array.wrap(source[:detect_on]).compact
          end

          def client_id(settings = {})
            client_id = source[:client_id]

            if client_id.is_a?(Proc)
              Dsl::WithDsl.execute(settings.with_indifferent_access, &client_id)
            else
              client_id
            end
          end

          def client_secret(settings = {})
            client_secret_source = source[:client_secret]

            if client_secret_source.is_a?(Proc)
              Dsl::WithDsl.execute(settings.with_indifferent_access, &client_secret_source)
            else
              client_secret_source
            end
          end

          def authorization_url(settings = {})
            source[:authorization_url]&.call(settings.with_indifferent_access)
          end

          def token_url(settings = {})
            source[:token_url]&.call(settings.with_indifferent_access)
          end

          def acquire(settings = {}, oauth2_code = nil, redirect_url = nil)
            acquire_proc = source[:acquire]
            raise InvalidDefinitionError, "Expect 'acquire' block" unless acquire_proc

            Workato::Connector::Sdk::Operation.new(
              connection: Connection.new(
                connection: connection_source.merge(
                  authorization: source.merge(
                    apply: nil
                  )
                ),
                methods: methods_source,
                settings: @settings
              ),
              methods: methods_source,
              settings: @settings
            ).execute(settings, { auth_code: oauth2_code, redirect_url: redirect_url }) do |connection, input|
              instance_exec(connection, input[:auth_code], input[:redirect_url], &acquire_proc)
            end
          end

          def refresh(settings = {}, refresh_token = nil)
            refresh_proc = source[:refresh]
            raise InvalidDefinitionError, "Expect 'refresh' block" unless refresh_proc

            Workato::Connector::Sdk::Operation.new(
              connection: Connection.new(
                methods: methods_source,
                settings: @settings
              ),
              methods: methods_source,
              settings: @settings
            ).execute(settings, { refresh_token: refresh_token }) do |connection, input|
              instance_exec(connection, input[:refresh_token], &refresh_proc)
            end
          end

          private

          attr_reader :connection_source,
                      :methods_source
        end

        private_constant :Authorization
      end
    end
  end
end
