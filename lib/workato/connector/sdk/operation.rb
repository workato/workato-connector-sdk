# frozen_string_literal: true

require_relative './dsl'
require_relative './block_invocation_refinements'

module Workato
  module Connector
    module Sdk
      class Operation
        include Dsl::Global
        include Dsl::HTTP
        include Dsl::Call
        include Dsl::Error

        using BlockInvocationRefinements

        cattr_accessor :on_settings_updated

        def initialize(connection:, operation: {}, methods: {}, settings: {}, object_definitions: nil)
          @connection = connection
          @settings = settings.with_indifferent_access
          @operation = operation.with_indifferent_access
          @_methods = methods.with_indifferent_access
          @object_definitions = object_definitions
        end

        def execute(settings = nil, input = {}, extended_input_schema = [], extended_output_schema = [], continue = {},
                    &block)
          @settings = settings.with_indifferent_access if settings # is being used in request for refresh tokens
          request_or_result = instance_exec(
            @settings.with_indifferent_access, # a copy of settings hash is being used in executable blocks
            input.with_indifferent_access,
            Array.wrap(extended_input_schema).map(&:with_indifferent_access),
            Array.wrap(extended_output_schema).map(&:with_indifferent_access),
            continue.with_indifferent_access,
            &block
          )
          resolve_request(request_or_result)
        end

        def extended_schema(settings = nil, config_fields = {})
          object_definitions_hash = object_definitions.lazy(settings, config_fields)
          {
            input: schema_fields(object_definitions_hash, settings, config_fields, &operation[:input_fields]),
            output: schema_fields(object_definitions_hash, settings, config_fields, &operation[:output_fields])
          }.with_indifferent_access
        end

        def input_fields(settings = nil, config_fields = {})
          object_definitions_hash = object_definitions.lazy(settings, config_fields)
          schema_fields(object_definitions_hash, settings, config_fields, &operation[:input_fields])
        end

        def output_fields(settings = nil, config_fields = {})
          object_definitions_hash = object_definitions.lazy(settings, config_fields)
          schema_fields(object_definitions_hash, settings, config_fields, &operation[:output_fields])
        end

        def summarize_input(input = {})
          summarize(input, operation[:summarize_input])
        end

        def summarize_output(output = {})
          summarize(output, operation[:summarize_output])
        end

        def sample_output(settings = nil, input = {})
          execute(settings, input, &operation[:sample_output])
        end

        def refresh_authorization!(http_code, http_body, exception, settings = {})
          return unless refresh_auth?(http_code, http_body, exception)

          new_settings = if /oauth2/i =~ connection.authorization.type
                           refresh_oauth2_token(settings)
                         elsif connection.authorization.acquire?
                           acquire_token(settings)
                         end
          return unless new_settings

          settings.merge!(new_settings)

          on_settings_updated&.call(http_body, http_code, exception, settings)

          settings
        end

        private

        def summarize(data, paths)
          return data unless paths.present?

          Summarize.new(data: data, paths: paths).call
        end

        def schema_fields(object_definitions_hash, settings, config_fields, &schema_proc)
          return {} unless schema_proc

          execute(settings, config_fields) do |connection, input|
            instance_exec(
              object_definitions_hash,
              connection,
              input,
              &schema_proc
            )
          end
        end

        def resolve_request(request_or_result)
          case request_or_result
          when Request
            resolve_request(request_or_result.execute!)
          when ::Array
            request_or_result.each_with_index.inject(request_or_result) do |acc, (item, index)|
              response_item = resolve_request(item)
              if response_item.equal?(item)
                acc
              else
                (acc == request_or_result ? acc.dup : acc).tap { |a| a[index] = response_item }
              end
            end
          when ::Hash
            request_or_result.inject(request_or_result.with_indifferent_access) do |acc, (key, value)|
              response_value = resolve_request(value)
              if response_value.equal?(value)
                acc
              else
                (acc == request_or_result ? acc.dup : acc).tap { |h| h[key] = response_value }
              end
            end
          else
            request_or_result
          end
        end

        def refresh_auth?(http_code, http_body, exception)
          refresh_on = connection.authorization.refresh_on
          refresh_on.blank? || refresh_on.any? do |pattern|
            pattern.is_a?(::Integer) && pattern == http_code ||
              pattern === exception&.to_s ||
              pattern === http_body
          end
        end

        def acquire_token(settings)
          connection.authorization.acquire(settings)
        end

        def refresh_oauth2_token_using_refresh(settings)
          new_tokens, new_settings = connection.authorization.refresh(settings, settings[:refresh_token])
          new_tokens.with_indifferent_access.merge(new_settings || {})
        end

        def refresh_oauth2_token_using_token_url(settings)
          if settings[:refresh_token].blank?
            raise NotImplementedError, 'refresh_token is empty. ' \
                                       'Use workato oauth2 command to acquire access_token and refresh_token'
          end

          response = RestClient::Request.execute(
            url: connection.authorization.token_url(settings),
            method: :post,
            payload: {
              client_id: connection.authorization.client_id(settings),
              client_secret: connection.authorization.client_secret(settings),
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

        def refresh_oauth2_token(settings)
          if connection.authorization.refresh?
            refresh_oauth2_token_using_refresh(settings)
          elsif connection.authorization.token_url?
            refresh_oauth2_token_using_token_url(settings)
          else
            raise InvalidDefinitionError, "'refresh' block or 'token_url' is required for refreshing the token"
          end
        end

        attr_reader :operation,
                    :connection,
                    :settings,
                    :object_definitions
      end
    end
  end
end
