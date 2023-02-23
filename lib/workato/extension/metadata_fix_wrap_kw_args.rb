# typed: false
# frozen_string_literal: true

require 'active_support/messages/metadata'

ActiveSupport::Messages::Metadata.singleton_class.prepend(
  Module.new do
    def wrap(message, opts = {})
      super(message, **opts)
    end
  end
)
