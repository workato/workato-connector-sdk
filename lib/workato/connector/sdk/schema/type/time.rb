# typed: true
# frozen_string_literal: true

require 'time'

module Workato
  module Connector
    module Sdk
      class Schema
        module Type
          class Time < ::Time
            PRECISION = 6

            def to_s(*args)
              if args.present?
                super
              else
                xmlschema(PRECISION)
              end
            end

            def self.from_time(value)
              new(
                value.year,
                value.month,
                value.day,
                value.hour,
                value.min,
                value.sec + Rational(value.nsec, 1_000_000_000),
                value.utc_offset
              )
            end

            def self.from_date_time(value)
              new(
                value.year,
                value.month,
                value.day,
                value.hour,
                value.min,
                value.sec + Rational(value.nsec, 1_000_000_000),
                value.zone
              )
            end

            def self.xmlschema(str)
              from_time(super)
            end
          end
        end
      end
    end
  end
end
