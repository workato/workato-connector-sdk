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
      format % (Array.wrap(val).map { |v| v.is_a?(ActiveSupport::HashWithIndifferentAccess) ? v.symbolize_keys : v })
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
end
