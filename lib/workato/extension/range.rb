# typed: false
# frozen_string_literal: true

# In Rails 7.1+ `to_fs` is the preferred method for formatting arrays
# and `to_s` patch was removed.
# We bring it back for a smooth upgrade.
module ActiveSupport
  module RangeWithFormat
    NOT_SET = Object.new unless defined?(NOT_SET)
    def to_s(format = NOT_SET)
      if (formatter = RangeWithFormat::RANGE_FORMATS[format])
        formatter.call(first, last)
      elsif format == NOT_SET
        if (formatter = RangeWithFormat::RANGE_FORMATS[:default])
          formatter.call(first, last)
        else
          super()
        end
      else
        super()
      end
    end
  end
end

Range.prepend(ActiveSupport::RangeWithFormat)
