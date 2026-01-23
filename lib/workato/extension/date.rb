# typed: false
# frozen_string_literal: true

module Workato
  module Extension
    module Date
      def yweek
        cweek
      end
    end
  end
end

Date.include(Workato::Extension::Date)
DateTime.include(Workato::Extension::Date)

# In Rails 7.1+ `to_fs` is the preferred method for formatting dates
# and `to_s` patch was removed.
# We bring it back for a smooth upgrade.
class Date
  alias_method :_workato_sdk_to_default_s, :to_s # rubocop:disable Style/Alias
  private :_workato_sdk_to_default_s

  NOT_SET = Object.new unless defined?(NOT_SET)
  def to_s(format = NOT_SET)
    if (formatter = DATE_FORMATS[format])
      if formatter.respond_to?(:call)
        formatter.call(self).to_s
      else
        strftime(formatter)
      end
    elsif format == NOT_SET
      if (formatter = DATE_FORMATS[:default])
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
end

# In Rails 7.1+ `to_fs` is the preferred method for formatting arrays
# and `to_s` patch was removed.
# We bring it back for a smooth upgrade.
class DateTime
  alias_method :_workato_sdk_to_default_s, :to_s # rubocop:disable Style/Alias
  private :_workato_sdk_to_default_s

  NOT_SET = Object.new unless defined?(NOT_SET)
  def to_s(format = NOT_SET)
    if (formatter = ::Time::DATE_FORMATS[format])
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
end
