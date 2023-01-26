# typed: false
# frozen_string_literal: true

module Workato
  module Connector
    module Sdk
      class Schema
        module Field
          module Convertors
            def render_input(value, custom_convertor = nil)
              apply_convertor(value, self[:render_input], custom_convertor)
            end

            def parse_output(value, custom_convertor = nil)
              apply_convertor(value, self[:parse_output], custom_convertor)
            end

            private

            def apply_convertor(value, builtin_convertor, custom_convertor)
              return value unless builtin_convertor || custom_convertor
              return send(builtin_convertor, value) if builtin_convertor && respond_to?(builtin_convertor, true)
              return custom_convertor.call(value) if custom_convertor.is_a?(Proc)

              raise ArgumentError, "Cannot find converter '#{builtin_convertor}'."
            end

            def integer_conversion(value)
              (value.try(:is_number?) && value.to_i) || value
            end

            def boolean_conversion(value)
              value.try(:is_true?)
            end

            def float_conversion(value)
              (value.try(:is_number?) && value.to_f) || value
            end

            def item_array_wrap(items)
              ::Array.wrap(items).presence&.flatten(1)
            end

            def date_conversion(value)
              parse_date(value)
            end

            def date_iso8601_conversion(value)
              parse_date(value)&.iso8601
            end

            def date_time_conversion(value)
              parse_date_time(value)
            end

            def date_time_iso8601_conversion(value)
              parse_date_time(value)&.iso8601
            end

            def convert_to_datetime(value)
              value.try(:to_datetime) || value
            end

            def convert_to_datetime_wo_tz(value)
              value.try(:to_datetime).strftime('%Y-%m-%d %H:%M:%S') || value
            end

            def parse_date_output(value)
              value.try(:to_date) || value
            end

            def render_date_input(value)
              try_in_time_zone(value).try(:to_date)
            end

            def convert_date_time(value)
              try_in_time_zone(value)
            end

            def parse_date_time_epoch_millis(value)
              if value.is_a?(::Time)
                value
              else
                value.is_a?(Numeric) && ::Time.at(value.to_f / 1000)
              end
            end

            def render_date_time_epoch_millis(value)
              value.try(:to_f).try(:*, 1000).try(:to_i)
            end

            def parse_iso8601_timestamp(value)
              if value.is_a?(::Time)
                value
              else
                value.try(:to_time)
              end
            end

            def render_iso8601_timestamp(value)
              value.try(:to_time).try(:iso8601)
            end

            def parse_iso8601_date(value)
              if value.is_a?(::Date)
                value
              else
                value.try(:to_date)
              end
            end

            def render_iso8601_date(value)
              value.try(:to_date).try(:iso8601)
            end

            def parse_epoch_time(value)
              if value.is_a?(::Time)
                value
              else
                (value.is_a?(Numeric).presence || value.try(:is_number?).presence) && ::Time.zone.at(value.to_i)
              end
            end

            def render_epoch_time(value)
              value.try(:to_time).try(:to_i)
            end

            def parse_float_epoch_time(value)
              if value.is_a?(::Time)
                value
              else
                (value.is_a?(Numeric) || value.try(:is_number?)) && ::Time.zone.at(value.to_f)
              end
            end

            def render_float_epoch_time(value)
              value.try(:to_time).try(:to_f)
            end

            def implicit_utc_time(value)
              value&.in_time_zone('UTC')
            end

            def implicit_utc_iso8601_time(value)
              value&.in_time_zone('UTC')&.iso8601
            end

            # Helpers
            #
            def try_in_time_zone(value)
              value.try(:in_time_zone, local_time_zone || ::Time.zone) || value
            end

            def local_time_zone
              ENV['WORKATO_TIME_ZONE'] || Workato::Connector::Sdk::DEFAULT_TIME_ZONE
            end

            def parse_date(value)
              if value.blank? || value.is_a?(::Date)
                value.presence
              elsif value.is_a?(::Time)
                value.to_date
              else
                parse_time_string(value).to_date
              end
            end

            def parse_date_time(value)
              if value.blank? || value.is_a?(::Time)
                value.presence
              elsif value.is_a?(::Date)
                value.in_time_zone(local_time_zone)
              else
                parse_time_string(value)
              end
            end

            def parse_time_string(value)
              value_time = ::Time.parse(value)
              user_time = ActiveSupport::TimeZone[local_time_zone].parse(value)

              # equal means value had its own offset/TZ or defaulted to system TZ with same offset as user's.
              value_time == user_time ? value_time : user_time
            end
          end
        end
      end
    end
  end
end
