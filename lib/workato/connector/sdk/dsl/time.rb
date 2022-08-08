# typed: true
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

begin
  if ENV['TZ'].present? && ENV['TZ'] != 'UTC'
    warn "WARNING: TZ environment variable is set to '#{ENV['TZ']}'. Set TZ=UTC for consistency with Workato platform'"
  else
    ENV['TZ'] = 'UTC'
  end
  ::Time.zone = Workato::Connector::Sdk::DEFAULT_TIME_ZONE
rescue TZInfo::DataSourceNotFound
  puts ''
  puts "tzinfo-data is not present. Please install gem 'tzinfo-data' by 'gem install tzinfo-data'"
  puts ''
  exit!
end
