# typed: true
# frozen_string_literal: true

module Workato
  module Extension
    module Currency
      class Countries
        extend T::Sig

        include Singleton

        class << self
          extend T::Sig

          sig { params(value: ::String).returns(T.nilable(Country)) }
          def find_country(value)
            instance.find_country(value)
          end
        end

        class State < T::Struct
          const :name, ::String
          const :names, T::Array[::String]
        end

        private_constant :State

        class Country < T::Struct
          const :name, ::String
          const :names, T::Array[::String]
          const :states, T::Hash[::String, State]
          const :alpha2, ::String
          const :alpha3, ::String
          const :number, ::String
          const :currency_code, T.nilable(::String)
        end

        private_constant :Country

        def initialize
          @countries = load_countries
        end

        sig { params(value: ::String).returns(T.nilable(Country)) }
        def find_country(value)
          value = value.upcase
          countries.find do |c|
            c.alpha2 == value || c.alpha3 == value || c.number == value || # already in upper case
              c.name.upcase == value || c.names.any? { |name| name.upcase == value }
          end
        end

        private

        sig { returns(T::Array[Country]) }
        attr_reader :countries

        sig { returns(T::Array[Country]) }
        def load_countries
          YAML.load_file(File.expand_path('./countries.yml', __dir__)).map do |data|
            Country.new(
              name: data['name'].freeze,
              names: data['names'].map!(&:freeze).freeze,
              alpha2: data['alpha2'].freeze,
              alpha3: data['alpha3'].freeze,
              number: data['number'].freeze,
              currency_code: data['currency']&.freeze,
              states: data['states'].transform_values do |s|
                State.new(name: s['name'].freeze, names: ::Array.wrap(s['names']).map!(&:freeze).freeze)
              end.freeze
            ).freeze
          end.freeze
        end
      end

      private_constant :Countries
    end
  end
end
