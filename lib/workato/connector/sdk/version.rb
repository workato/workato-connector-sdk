# typed: strict
# frozen_string_literal: true

module Workato
  module Connector
    module Sdk
      VERSION = T.let(File.read(File.expand_path('../../../../VERSION', __dir__)).strip, String)
    end
  end
end
