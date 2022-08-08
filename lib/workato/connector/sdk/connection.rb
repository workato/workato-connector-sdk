# typed: strict
# frozen_string_literal: true

require_relative './block_invocation_refinements'

module Workato
  module Connector
    module Sdk
      class Connection
        extend T::Sig

        using BlockInvocationRefinements

        sig { returns(HashWithIndifferentAccess) }
        attr_reader :source

        cattr_accessor :on_settings_update

        sig do
          params(
            connection: SorbetTypes::SourceHash,
            methods: SorbetTypes::SourceHash,
            settings: SorbetTypes::SettingsHash
          ).void
        end
        def initialize(connection: {}, methods: {}, settings: {})
          @methods_source = T.let(methods.with_indifferent_access, HashWithIndifferentAccess)
          @source = T.let(connection.with_indifferent_access, HashWithIndifferentAccess)
          @settings = T.let(settings, SorbetTypes::SettingsHash)
        end

        sig { returns(SorbetTypes::SettingsHash) }
        def settings!
          @settings
        end

        sig { returns(HashWithIndifferentAccess) }
        def settings
          # we can't freeze or memoise because some developers modify it for storing something temporary in it.
          @settings.with_indifferent_access
        end

        sig { params(settings: SorbetTypes::SettingsHash).returns(SorbetTypes::SettingsHash) }
        def merge_settings!(settings)
          @settings.merge!(settings)
        end

        sig { returns(T::Boolean) }
        def authorization?
          source[:authorization].present?
        end

        sig { returns(Authorization) }
        def authorization
          raise ::NotImplementedError, 'define authorization: before use' if source[:authorization].blank?

          @authorization = T.let(@authorization, T.nilable(Authorization))
          @authorization ||= Authorization.new(
            connection: self,
            authorization: source[:authorization],
            methods: methods_source
          )
        end

        sig { params(settings: T.nilable(SorbetTypes::SettingsHash)).returns(T.nilable(String)) }
        def base_uri(settings = nil)
          source[:base_uri]&.call(settings ? settings.with_indifferent_access.freeze : self.settings)
        end

        sig do
          params(
            message: String,
            refresher: T.proc.returns(T.nilable(SorbetTypes::SettingsHash))
          ).returns(T::Boolean)
        end
        def update_settings!(message, &refresher)
          updater = lambda do
            new_settings = refresher.call
            next unless new_settings

            settings.merge(new_settings)
          end

          new_settings = if on_settings_update
                           on_settings_update.call(message, &updater)
                         else
                           updater.call
                         end
          return false unless new_settings

          merge_settings!(new_settings)

          true
        end

        private

        sig { returns(HashWithIndifferentAccess) }
        attr_reader :methods_source

        class Authorization
          extend T::Sig

          sig { returns(HashWithIndifferentAccess) }
          attr_reader :source

          sig do
            params(
              connection: Connection,
              authorization: HashWithIndifferentAccess,
              methods: HashWithIndifferentAccess
            ).void
          end
          def initialize(connection:, authorization:, methods:)
            @connection = T.let(connection, Connection)
            @connection_source = T.let(connection.source, HashWithIndifferentAccess)
            @source = T.let(authorization, HashWithIndifferentAccess)
            @methods_source = T.let(methods, HashWithIndifferentAccess)
          end

          sig { returns(String) }
          def type
            (source[:type].presence || 'none').to_s
          end

          sig { returns(T::Array[T.any(String, Symbol, Regexp, Integer)]) }
          def refresh_on
            Array.wrap(source[:refresh_on]).compact
          end

          sig { returns(T::Array[T.any(String, Symbol, Regexp, Integer)]) }
          def detect_on
            Array.wrap(source[:detect_on]).compact
          end

          sig { params(settings: T.nilable(SorbetTypes::SettingsHash)).returns(T.nilable(String)) }
          def client_id(settings = nil)
            client_id = source[:client_id]

            if client_id.is_a?(Proc)
              @connection.merge_settings!(settings) if settings
              Dsl::WithDsl.execute(@connection, @connection.settings, &client_id)
            else
              client_id
            end
          end

          sig { params(settings: T.nilable(SorbetTypes::SettingsHash)).returns(T.nilable(String)) }
          def client_secret(settings = nil)
            client_secret_source = source[:client_secret]

            if client_secret_source.is_a?(Proc)
              @connection.merge_settings!(settings) if settings
              Dsl::WithDsl.execute(@connection, @connection.settings, &client_secret_source)
            else
              client_secret_source
            end
          end

          sig { params(settings: T.nilable(SorbetTypes::SettingsHash)).returns(T.nilable(String)) }
          def authorization_url(settings = nil)
            source[:authorization_url]&.call(settings&.with_indifferent_access || @connection.settings)
          end

          sig { params(settings: T.nilable(SorbetTypes::SettingsHash)).returns(T.nilable(String)) }
          def token_url(settings = nil)
            source[:token_url]&.call(settings&.with_indifferent_access || @connection.settings)
          end

          sig do
            params(
              settings: T.nilable(SorbetTypes::SettingsHash),
              oauth2_code: T.nilable(String),
              redirect_url: T.nilable(String)
            ).returns(HashWithIndifferentAccess)
          end
          def acquire(settings = nil, oauth2_code = nil, redirect_url = nil)
            acquire_proc = source[:acquire]
            raise InvalidDefinitionError, "Expect 'acquire' block" unless acquire_proc

            Workato::Connector::Sdk::Operation.new(
              connection: Connection.new(
                connection: connection_source.merge(
                  authorization: source.merge(
                    apply: nil # only skip apply authorization for re-authorization request
                  )
                ),
                methods: methods_source,
                settings: @connection.settings!
              ),
              methods: methods_source
            ).execute(settings, { auth_code: oauth2_code, redirect_url: redirect_url }) do |connection, input|
              instance_exec(connection, input[:auth_code], input[:redirect_url], &acquire_proc)
            end
          end

          sig do
            params(
              http_code: T.nilable(Integer),
              http_body: T.nilable(String),
              exception: T.nilable(String)
            ).returns(T::Boolean)
          end
          def refresh?(http_code, http_body, exception)
            refresh_on = self.refresh_on
            refresh_on.blank? || refresh_on.any? do |pattern|
              pattern.is_a?(::Integer) && pattern == http_code ||
                pattern === exception&.to_s ||
                pattern === http_body
            end
          end

          sig { params(settings: HashWithIndifferentAccess).returns(T.nilable(HashWithIndifferentAccess)) }
          def refresh!(settings)
            if /oauth2/i =~ type
              refresh_oauth2_token(settings)
            elsif source[:acquire].present?
              acquire(settings)
            end
          end

          sig do
            params(
              settings: T.nilable(SorbetTypes::SettingsHash),
              refresh_token: T.nilable(String)
            ).returns(
              T.any([HashWithIndifferentAccess, T.nilable(String)], HashWithIndifferentAccess)
            )
          end
          def refresh(settings = nil, refresh_token = nil)
            refresh_proc = source[:refresh]
            raise InvalidDefinitionError, "Expect 'refresh' block" unless refresh_proc

            Workato::Connector::Sdk::Operation.new(
              connection: Connection.new(
                methods: methods_source,
                settings: @connection.settings!
              ),
              methods: methods_source
            ).execute(settings, { refresh_token: refresh_token }) do |connection, input|
              instance_exec(connection, input[:refresh_token], &refresh_proc)
            end
          end

          private

          sig { returns(HashWithIndifferentAccess) }
          attr_reader :connection_source

          sig { returns(HashWithIndifferentAccess) }
          attr_reader :methods_source

          sig { params(settings: HashWithIndifferentAccess).returns(HashWithIndifferentAccess) }
          def refresh_oauth2_token(settings)
            if source[:refresh].present?
              refresh_oauth2_token_using_refresh(settings)
            elsif source[:token_url].present?
              refresh_oauth2_token_using_token_url(settings)
            else
              raise InvalidDefinitionError, "'refresh' block or 'token_url' is required for refreshing the token"
            end
          end

          sig { params(settings: HashWithIndifferentAccess).returns(HashWithIndifferentAccess) }
          def refresh_oauth2_token_using_refresh(settings)
            new_tokens, new_settings = refresh(settings, settings[:refresh_token])
            new_tokens.with_indifferent_access.merge(new_settings || {})
          end

          sig { params(settings: HashWithIndifferentAccess).returns(HashWithIndifferentAccess) }
          def refresh_oauth2_token_using_token_url(settings)
            if settings[:refresh_token].blank?
              raise NotImplementedError, 'refresh_token is empty. ' \
                                       'Use workato oauth2 command to acquire access_token and refresh_token'
            end

            response = RestClient::Request.execute(
              url: token_url(settings),
              method: :post,
              payload: {
                client_id: client_id(settings),
                client_secret: client_secret(settings),
                grant_type: :refresh_token,
                refresh_token: settings[:refresh_token]
              },
              headers: {
                accept: :json
              }
            )
            tokens = JSON.parse(response.body)
            {
              access_token: tokens['access_token'],
              refresh_token: tokens['refresh_token'].presence || settings[:refresh_token]
            }.with_indifferent_access
          end
        end

        private_constant :Authorization
      end
    end
  end
end
