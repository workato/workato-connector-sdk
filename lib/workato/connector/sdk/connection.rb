# typed: strict
# frozen_string_literal: true

require_relative 'block_invocation_refinements'

module Workato
  module Connector
    module Sdk
      module SorbetTypes
        AcquireOutput = T.type_alias do
          T.any(
            # oauth2
            [
              ActiveSupport::HashWithIndifferentAccess, # tokens
              T.untyped, # resource_owner_id
              T.nilable(ActiveSupport::HashWithIndifferentAccess) # settings
            ],
            [
              ActiveSupport::HashWithIndifferentAccess, # tokens
              T.untyped # resource_owner_id
            ],
            [
              ActiveSupport::HashWithIndifferentAccess # tokens
            ],
            # custom_auth
            ActiveSupport::HashWithIndifferentAccess
          )
        end

        RefreshOutput = T.type_alias do
          T.any(
            [
              ActiveSupport::HashWithIndifferentAccess, # tokens
              T.nilable(ActiveSupport::HashWithIndifferentAccess) # settings
            ],
            [
              ActiveSupport::HashWithIndifferentAccess # tokens
            ],
            ActiveSupport::HashWithIndifferentAccess # tokens
          )
        end
      end

      class Connection
        extend T::Sig
        include MonitorMixin

        using BlockInvocationRefinements # rubocop:disable Sorbet/Refinement core SDK feature

        # @api private
        sig { returns(ActiveSupport::HashWithIndifferentAccess) }
        attr_reader :source

        class_attribute :on_settings_update, instance_predicate: false
        class_attribute :multi_auth_selected_fallback, instance_predicate: false

        sig do
          params(
            connection: SorbetTypes::SourceHash,
            methods: SorbetTypes::SourceHash,
            settings: SorbetTypes::SettingsHash
          ).void
        end
        def initialize(connection: {}, methods: {}, settings: {})
          super()
          @methods_source = T.let(
            Utilities::HashWithIndifferentAccess.wrap(methods),
            ActiveSupport::HashWithIndifferentAccess
          )
          @source = T.let(
            Utilities::HashWithIndifferentAccess.wrap(connection),
            ActiveSupport::HashWithIndifferentAccess
          )
          @settings = T.let(settings, SorbetTypes::SettingsHash)
        end

        # @api private
        sig { returns(SorbetTypes::SettingsHash) }
        def settings!
          @settings
        end

        # @api private
        sig { returns(ActiveSupport::HashWithIndifferentAccess) }
        def settings
          # we can't freeze or memoise because some developers modify it for storing something temporary in it.
          # always return a new copy
          synchronize do
            @settings.with_indifferent_access
          end
        end

        # @api private
        sig { params(settings: SorbetTypes::SettingsHash).returns(SorbetTypes::SettingsHash) }
        def merge_settings!(settings)
          @settings.merge!(settings)
        end

        # @api private
        sig { returns(T::Boolean) }
        def authorization?
          source[:authorization].present?
        end

        sig { returns(Authorization) }
        def authorization
          raise ::NotImplementedError, 'define authorization: before use' if source[:authorization].blank?

          @authorization ||= T.let(
            Authorization.new(
              connection: self,
              authorization: source[:authorization],
              methods: methods_source
            ),
            T.nilable(Authorization)
          )
        end

        sig { params(settings: T.nilable(SorbetTypes::SettingsHash)).returns(T.nilable(String)) }
        def base_uri(settings = nil)
          return unless source[:base_uri]

          merge_settings!(settings) if settings
          global_dsl_context.execute(self.settings, &source['base_uri'])
        end

        # @api private
        sig do
          params(
            message: String,
            settings_before: SorbetTypes::SettingsHash,
            refresher: T.proc.returns(T.nilable(SorbetTypes::SettingsHash))
          ).returns(T::Boolean)
        end
        def update_settings!(message, settings_before, &refresher)
          updater = lambda do
            new_settings = refresher.call
            next unless new_settings

            settings.merge(new_settings)
          end

          synchronize do
            new_settings = if on_settings_update
                             T.must(on_settings_update).call(message, settings_before, updater)
                           else
                             updater.call
                           end
            return false unless new_settings

            merge_settings!(new_settings)

            true
          end
        end

        private

        sig { returns(ActiveSupport::HashWithIndifferentAccess) }
        attr_reader :methods_source

        sig { returns(Dsl::WithDsl) }
        def global_dsl_context
          Dsl::WithDsl.new(self)
        end

        class Authorization
          extend T::Sig

          sig do
            params(
              connection: Connection,
              authorization: ActiveSupport::HashWithIndifferentAccess,
              methods: ActiveSupport::HashWithIndifferentAccess
            ).void
          end
          def initialize(connection:, authorization:, methods:)
            @connection = T.let(connection, Connection)
            @connection_source = T.let(connection.source, ActiveSupport::HashWithIndifferentAccess)
            @source = T.let(authorization, ActiveSupport::HashWithIndifferentAccess)
            @methods_source = T.let(methods, ActiveSupport::HashWithIndifferentAccess)
          end

          sig { returns(String) }
          def type
            (source[:type].presence || 'none').to_s
          end

          sig { returns(T::Boolean) }
          def oauth2?
            !!(/oauth2/i =~ type)
          end

          sig { returns(T::Boolean) }
          def multi?
            @source[:type].to_s == 'multi'
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
            @connection.merge_settings!(settings) if settings
            client_id = source[:client_id]

            if client_id.is_a?(Proc)
              global_dsl_context.execute(@connection.settings, &client_id)
            else
              client_id
            end
          end

          sig { params(settings: T.nilable(SorbetTypes::SettingsHash)).returns(T.nilable(String)) }
          def client_secret(settings = nil)
            @connection.merge_settings!(settings) if settings
            client_secret_source = source[:client_secret]

            if client_secret_source.is_a?(Proc)
              global_dsl_context.execute(@connection.settings, &client_secret_source)
            else
              client_secret_source
            end
          end

          sig { params(settings: T.nilable(SorbetTypes::SettingsHash)).returns(T.nilable(String)) }
          def authorization_url(settings = nil)
            @connection.merge_settings!(settings) if settings
            return unless source[:authorization_url]

            global_dsl_context.execute(@connection.settings, &source[:authorization_url])
          end

          sig { params(settings: T.nilable(SorbetTypes::SettingsHash)).returns(T.nilable(String)) }
          def token_url(settings = nil)
            @connection.merge_settings!(settings) if settings
            return unless source[:token_url]

            global_dsl_context.execute(@connection.settings, &source[:token_url])
          end

          sig do
            params(
              settings: T.nilable(SorbetTypes::SettingsHash),
              oauth2_code: T.nilable(String),
              redirect_url: T.nilable(String)
            ).returns(T.nilable(SorbetTypes::AcquireOutput))
          end
          def acquire(settings = nil, oauth2_code = nil, redirect_url = nil)
            @connection.merge_settings!(settings) if settings
            acquire_proc = source[:acquire]
            raise InvalidDefinitionError, "Expect 'acquire' block" unless acquire_proc

            Workato::Connector::Sdk::Operation.new(
              connection: Connection.new(
                connection: connection_source.merge(
                  authorization: source.merge(
                    apply: nil # only skip apply authorization for re-authorization request, but don't skip detect_on
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

          sig { returns(T::Boolean) }
          def reauthorizable?
            oauth2? || source[:acquire].present?
          end

          sig do
            params(
              http_code: T.nilable(Integer),
              http_body: T.nilable(String),
              exception: T.nilable(String)
            ).returns(T::Boolean)
          end
          def refresh?(http_code, http_body, exception)
            return false unless reauthorizable?

            refresh_on = self.refresh_on
            refresh_on.blank? || refresh_on.any? do |pattern|
              (pattern.is_a?(::Integer) && pattern == http_code) ||
                pattern === exception&.to_s ||
                pattern === http_body
            end
          end

          # @api private
          sig do
            params(
              settings: ActiveSupport::HashWithIndifferentAccess
            ).returns(T.nilable(ActiveSupport::HashWithIndifferentAccess))
          end
          def refresh!(settings)
            if oauth2?
              refresh_oauth2_token(settings)
            elsif source[:acquire].present?
              T.cast(acquire(settings), T.nilable(ActiveSupport::HashWithIndifferentAccess))
            end
          end

          sig do
            params(
              settings: T.nilable(SorbetTypes::SettingsHash),
              refresh_token: T.nilable(String)
            ).returns(SorbetTypes::RefreshOutput)
          end
          def refresh(settings = nil, refresh_token = nil)
            @connection.merge_settings!(settings) if settings
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

          # @api private
          sig { returns(ActiveSupport::HashWithIndifferentAccess) }
          def source
            return @source unless multi?

            unless @source[:selected]
              raise InvalidMultiAuthDefinition, "Multi-auth connection must define 'selected' block"
            end

            if @source[:options].blank?
              raise InvalidMultiAuthDefinition, "Multi-auth connection must define 'options' list"
            end

            selected_auth_key = @source[:selected].call(@connection.settings)
            selected_auth_key ||= @connection.multi_auth_selected_fallback&.call(@source[:options])
            selected_auth_value = @source.dig(:options, selected_auth_key)

            raise UnresolvedMultiAuthOptionError, selected_auth_key unless selected_auth_value

            selected_auth_value
          end

          private

          sig { returns(ActiveSupport::HashWithIndifferentAccess) }
          attr_reader :connection_source

          sig { returns(ActiveSupport::HashWithIndifferentAccess) }
          attr_reader :methods_source

          sig do
            params(
              settings: ActiveSupport::HashWithIndifferentAccess
            ).returns(ActiveSupport::HashWithIndifferentAccess)
          end
          def refresh_oauth2_token(settings)
            if source[:refresh].present?
              refresh_oauth2_token_using_refresh(settings)
            elsif source[:token_url].present?
              refresh_oauth2_token_using_token_url(settings)
            else
              raise InvalidDefinitionError, "'refresh' block or 'token_url' is required for refreshing the token"
            end
          end

          sig do
            params(
              settings: ActiveSupport::HashWithIndifferentAccess
            ).returns(ActiveSupport::HashWithIndifferentAccess)
          end
          def refresh_oauth2_token_using_refresh(settings)
            new_tokens, new_settings = refresh(settings, settings[:refresh_token])
            new_tokens = Utilities::HashWithIndifferentAccess.wrap(new_tokens)
            return new_tokens unless new_settings

            new_tokens.merge(new_settings)
          end

          sig do
            params(
              settings: ActiveSupport::HashWithIndifferentAccess
            ).returns(ActiveSupport::HashWithIndifferentAccess)
          end
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

          sig { returns(Dsl::WithDsl) }
          def global_dsl_context
            Dsl::WithDsl.new(@connection)
          end
        end
      end
    end
  end
end
