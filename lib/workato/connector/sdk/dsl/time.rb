# frozen_string_literal: true

module Workato
  module Connector
    module Sdk
      module Dsl
        module Time
          def now
            ::Time.zone.now
          end

          def today
            ::Time.zone.today
          end
        end
      end
    end
  end
end

::Time.zone = Workato::Connector::Sdk::DEFAULT_TIME_ZONE
