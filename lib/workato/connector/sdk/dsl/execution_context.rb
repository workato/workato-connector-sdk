# typed: true
# frozen_string_literal: true

require 'securerandom'
require 'active_support/core_ext/class/attribute'

module Workato
  module Connector
    module Sdk
      module Dsl
        module ExecutionContext
          extend T::Sig
          extend T::Helpers
          extend ActiveSupport::Concern

          included do
            T.bind(self, Class)

            # encrypted safe recipe_id
            class_attribute :recipe_id, instance_predicate: false, default: SecureRandom.hex(32)
          end

          sig { returns(T::Hash[Symbol, T.untyped]) }
          def execution_context
            @execution_context ||= {
              recipe_id: recipe_id
            }.compact
          end

          # mock unencrypted recipe_id for testing only
          def recipe_id!
            recipe_id.reverse
          end

          module ClassMethods
            # mock unencrypted recipe_id for testing only
            def recipe_id!
              T.unsafe(self).recipe_id.reverse
            end
          end

          private_constant :ClassMethods
        end
      end
    end
  end
end
