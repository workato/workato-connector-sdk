# typed: false
# frozen_string_literal: true

module Workato
  module Extension
    module Time
      def yweek
        to_date.cweek
      end
    end
  end
end

Time.include(Workato::Extension::Time)

# In Rails 7.1+ `to_fs` is the preferred method for formatting arrays
# and `to_s` patch was removed.
# We bring it back for a smooth upgrade.
class Time
  alias_method :_workato_sdk_to_default_s, :to_s # rubocop:disable Style/Alias
  private :_workato_sdk_to_default_s

  NOT_SET = Object.new unless defined?(NOT_SET)
  def to_s(format = NOT_SET)
    if (formatter = DATE_FORMATS[format])
      formatter.respond_to?(:call) ? formatter.call(self).to_s : strftime(formatter)
    elsif format == NOT_SET
      if (formatter = ::Time::DATE_FORMATS[:default])
        if formatter.respond_to?(:call)
          formatter.call(self).to_s
        else
          strftime(formatter)
        end
      else
        _workato_sdk_to_default_s
      end
    else
      _workato_sdk_to_default_s
    end
  end

  unless public_instance_methods.include?(:to_fs)
    alias_method :to_fs, :to_s # rubocop:disable Style/Alias
  end
end

# In Rails 7.1+ `to_fs` is the preferred method for formatting arrays
# and `to_s` patch was removed.
# We bring it back for a smooth upgrade.
module ActiveSupport
  class TimeWithZone
    NOT_SET = Object.new unless defined?(NOT_SET)

    def to_s(format = NOT_SET)
      if format == :db
        utc.to_fs(format)
      elsif (formatter = ::Time::DATE_FORMATS[format])
        formatter.respond_to?(:call) ? formatter.call(self).to_s : strftime(formatter)
      elsif format == NOT_SET
        if (formatter = ::Time::DATE_FORMATS[:default])
          formatter.respond_to?(:call) ? formatter.call(self).to_s : strftime(formatter)
        else
          "#{time.strftime('%Y-%m-%d %H:%M:%S')} #{formatted_offset(false, 'UTC')}" # mimicking Ruby Time#to_s format
        end
      else
        "#{time.strftime('%Y-%m-%d %H:%M:%S')} #{formatted_offset(false, 'UTC')}" # mimicking Ruby Time#to_s format
      end
    end
  end
end
