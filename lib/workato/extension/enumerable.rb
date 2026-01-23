# typed: false
# frozen_string_literal: true

module Enumerable
  def where(options = {})
    obj = first
    list = if obj.is_a?(::Hash)
             self
           else
             []
           end
    Workato::Extension::Array::ArrayWhere.new(list, options || {})
  end

  def format_map(format)
    if format.blank?
      return self
    end

    map do |val|
      format % Array.wrap(val).map { |v| v.is_a?(ActiveSupport::HashWithIndifferentAccess) ? v.symbolize_keys : v }
    end
  end

  def smart_join(separator)
    transform_select do |val|
      val = val.strip if val.is_a?(::String)
      val.presence
    end.join(separator)
  end

  def pluck(*keys)
    if keys.many?
      map { |element| keys.map { |key| element.respond_to?(:dig) ? element.dig(*key) : element[key] } }
    else
      map { |element| element.respond_to?(:dig) ? element.dig(*keys.first) : element[keys.first] }
    end
  end

  def transform_find(&block)
    each do |*items|
      result = block.call(*items)
      return result if result
    end
    nil
  end

  def transform_select(&block)
    map do |*items|
      result = block.call(*items)
      result || nil
    end.compact
  end

  # In Rails 7.1+, Ruby's `sum` is the preferred implementation.
  # and `sum` patch was removed from ActiveSupport.
  # We bring it back for a smooth upgrade.
  alias_method :_workato_sdk_original_sum_with_required_identity, :sum # rubocop:disable Style/Alias
  private :_workato_sdk_original_sum_with_required_identity

  # Calculates a sum from the elements.
  #
  #   payments.sum { |p| p.price * p.tax_rate }
  #   payments.sum(&:price)
  #
  # The latter is a shortcut for:
  #
  #   payments.inject(0) { |sum, p| sum + p.price }
  #
  # It can also calculate the sum without the use of a block.
  #
  #   [5, 15, 10].sum # => 30
  #   ['foo', 'bar'].sum('') # => "foobar"
  #   [[1, 2], [3, 1, 5]].sum([]) # => [1, 2, 3, 1, 5]
  #
  # The default sum of an empty list is zero. You can override this default:
  #
  #   [].sum(Payment.new(0)) { |i| i.amount } # => Payment.new(0)
  def sum(identity = nil, &block)
    if identity
      _workato_sdk_original_sum_with_required_identity(identity, &block)
    elsif block_given?
      map(&block).sum
    else
      first = true

      reduce(nil) do |sum, value|
        if first
          first = false
          value
        else
          sum + value
        end
      end || 0
    end
  end
end
