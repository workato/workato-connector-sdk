# typed: true
# frozen_string_literal: true

require 'nokogiri'

module Workato
  module Utilities
    module Xml
      class << self
        def parse_xml_to_hash(payload, strip_namespaces: false)
          parse_options = Nokogiri::XML::ParseOptions.new.nonet
          lazy_reader = Nokogiri::XML::Reader(payload, nil, nil, parse_options).to_enum.lazy
          lazy_reader.each_with_object([{}]) do |node, ancestors|
            ancestors.shift while ancestors.count > node.depth + 1
            case node.node_type
            when Nokogiri::XML::Reader::TYPE_ELEMENT
              element = ActiveSupport::HashWithIndifferentAccess.new
              node.attributes&.each do |name, value|
                element["@#{strip_namespaces ? name[/(?:^xmlns:)?[^:]+$/] : name}"] = value
              end
              (ancestors.first[strip_namespaces ? node.name[/[^:]+$/] : node.name] ||= []).push(element)
              ancestors.unshift(element)
            when Nokogiri::XML::Reader::TYPE_TEXT, Nokogiri::XML::Reader::TYPE_CDATA
              element = ancestors.first
              if element.key?(:content!)
                element[:content!] += node.value
              else
                element[:content!] = node.value
              end
            end
          end.last
        end
      end
    end
  end
end
