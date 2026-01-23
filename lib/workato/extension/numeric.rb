# typed: true
# frozen_string_literal: true

# In Rails 7.1+ `to_fs` is the preferred method for formatting numbers
# and `to_s` patch was removed.
# We bring it back for a smooth upgrade.
module ActiveSupport
  module NumericWithFormat
    def to_s(format = nil, options = nil)
      return super() if format.nil?

      case format
      when :phone
        ActiveSupport::NumberHelper.number_to_phone(self, options || {})
      when :currency
        ActiveSupport::NumberHelper.number_to_currency(self, options || {})
      when :percentage
        ActiveSupport::NumberHelper.number_to_percentage(self, options || {})
      when :delimited
        ActiveSupport::NumberHelper.number_to_delimited(self, options || {})
      when :rounded
        ActiveSupport::NumberHelper.number_to_rounded(self, options || {})
      when :human
        ActiveSupport::NumberHelper.number_to_human(self, options || {})
      when :human_size
        ActiveSupport::NumberHelper.number_to_human_size(self, options || {})
      when Symbol
        super()
      else
        super(format)
      end
    end
  end
end

Integer.prepend ActiveSupport::NumericWithFormat
Float.prepend ActiveSupport::NumericWithFormat
BigDecimal.prepend ActiveSupport::NumericWithFormat
