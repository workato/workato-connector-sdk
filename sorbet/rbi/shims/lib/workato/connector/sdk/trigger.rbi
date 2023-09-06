# frozen_string_literal: true
# typed: strict

module Workato
  module Connector
    module Sdk
      class Trigger
        sig { returns(ActiveSupport::HashWithIndifferentAccess) }
        def operation; end
      end
    end
  end
end
