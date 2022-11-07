# typed: false
# frozen_string_literal: true

require 'rails-html-sanitizer'
require 'workato/utilities/xml'

module Workato
  module Extension
    module String
      HUMAN_DATE_FP = { '%d' => 'DD', '%m' => 'MM', '%Y' => 'YYYY' }.freeze
      HUMAN_DATE_FORMAT = %w[%d %m %Y].permutation(3).each_with_object({}) do |fmt, r|
        %w[/ -].each do |s|
          v = fmt.join(s)
          k = fmt.map { |fp| HUMAN_DATE_FP[fp] }.join(s)
          r[k] = v
        end
      end
      TO_COUNTRY_METHODS = %w[alpha2 alpha3 name number].freeze
      TO_CURRENCY_METHODS = %w[code name symbol].freeze
      TO_STATE_METHODS = %w[code name].freeze

      def is_int? # rubocop:disable Naming/PredicateName
        present? && (self !~ /\D/)
      end

      def is_number? # rubocop:disable Naming/PredicateName
        return false if blank?

        match?(/^\d+$/) ||
          begin
            Float(self)
          rescue StandardError
            false
          end.present?
      end

      def split_strip_compact(pattern, parts = 0)
        split(pattern, parts).map(&:strip).select(&:present?)
      end

      def strip_tags
        @html_full_sanitizer ||= Rails::Html::Sanitizer.full_sanitizer.new
        @html_full_sanitizer.sanitize(self)
      end

      def to_time(form = :local, format: nil)
        if format.present?
          format = HUMAN_DATE_FORMAT[format] if HUMAN_DATE_FORMAT.key?(format)
          time = ::Time.strptime(self, format)
          form == :utc ? time.utc : time.getlocal
        else
          super form
        end
      end

      def quote
        gsub("'", "''")
      end

      def to_date(format: nil)
        if format.present?
          format = HUMAN_DATE_FORMAT[format] if HUMAN_DATE_FORMAT.key?(format)
          ::Date.strptime(self, format)
        else
          super()
        end
      end

      def transliterate(replacement = '?')
        I18n.transliterate(self, replacement)
      end

      def labelize(*acronyms)
        acronyms.unshift(/^id$/i, /^ur[il]$/i)
        split(/_+ # snake_case => Snake case
              |
              (?<!\d)(?=\d)|(?<=\d)(?!\d) # concatenated42numbers => Concatenated 42 numbers
              |
              (?<![A-Z])(?=[A-Z]) # camelCase => Camel case
              |
              (?<=[A-Z0-9])(?=[A-Z][^A-Z0-9_] # MIXEDCase => Mixed case
             )/x).select(&:present?).map.with_index do |word, i|
          if /^[A-Z]+$/ =~ word
            word
          elsif acronyms.any? { |pattern| pattern =~ word }
            word.upcase
          elsif i.zero?
            word.humanize
          else
            word.downcase
          end
        end.join(' ')
      end

      def to_hex
        unpack('H*')[0]
      end

      def base64
        encode_base64
      end

      alias encode_hex to_hex

      def decode_hex
        Extension::Binary.new([self].pack('H*'))
      end

      def encode_base64
        Base64.strict_encode64(self)
      end

      def decode_base64
        Extension::Binary.new(Base64.decode64(self))
      end

      def encode_urlsafe_base64
        Base64.urlsafe_encode64(self)
      end

      def encode_url
        ::ERB::Util.url_encode(self)
      end

      def decode_url
        CGI.unescape(self)
      end

      def decode_urlsafe_base64
        Extension::Binary.new(Base64.urlsafe_decode64(self))
      end

      def encode_sha256
        Extension::Binary.new(::Digest::SHA256.digest(self))
      end

      def hmac_sha256(key)
        digest = ::OpenSSL::Digest.new('sha256')
        Extension::Binary.new(::OpenSSL::HMAC.digest(digest, key, self))
      end

      def hmac_sha512(key)
        digest = ::OpenSSL::Digest.new('sha512')
        Extension::Binary.new(::OpenSSL::HMAC.digest(digest, key, self))
      end

      def rsa_sha256(key)
        digest = ::OpenSSL::Digest.new('sha256')
        private_key = ::OpenSSL::PKey::RSA.new(key)
        Workato::Extension::Binary.new(private_key.sign(digest, self))
      end

      def md5_hexdigest
        ::Digest::MD5.hexdigest(self)
      end

      def sha1
        Extension::Binary.new(::Digest::SHA1.digest(self))
      end

      def hmac_sha1(key)
        digest = ::OpenSSL::Digest.new('sha1')
        Extension::Binary.new(::OpenSSL::HMAC.digest(digest, key, self))
      end

      def hmac_md5(key)
        digest = ::OpenSSL::Digest.new('md5')
        Extension::Binary.new(::OpenSSL::HMAC.digest(digest, key, self))
      end

      def from_xml
        Workato::Utilities::Xml.parse_xml_to_hash(self)
      end

      TO_COUNTRY_METHODS.each do |suffix|
        define_method("to_country_#{suffix}") do
          to_country.try(suffix)
        end
      end

      TO_CURRENCY_METHODS.each do |suffix|
        define_method("to_currency_#{suffix}") do
          to_currency_obj.try(suffix)
        end
      end

      TO_STATE_METHODS.each do |suffix|
        define_method("to_state_#{suffix}") do |country_name = 'US'|
          to_state(country_name).try(:[], suffix)
        end
      end

      protected

      def to_country
        TO_COUNTRY_METHODS.transform_find do |attr|
          ISO3166::Country.send("find_country_by_#{attr}", self)
        end
      end

      def to_currency_obj
        ISO4217::Currency.from_code(self) || to_country.try(:currency)
      end

      def to_state(country_name = 'US')
        country_name = country_name.presence || 'US'
        country = country_name.to_country
        return nil if country.blank?

        state = upcase
        country.states.transform_find do |code, data|
          name = data['name'].upcase
          other_names = Array(data['names']).map(&:upcase)
          if code == state || name == state || other_names.include?(state)
            {
              code: code,
              name: name
            }.with_indifferent_access
          end
        end
      end
    end

    class Binary < ::String
      TITLE_LENGTH = 16
      SUMMARY_LENGTH = 128

      def initialize(str)
        super(str)
        force_encoding(Encoding::ASCII_8BIT)
      end

      def to_s
        self
      end

      def to_json(_options = nil)
        summary
      end

      def binary?
        true
      end

      def base64
        Base64.strict_encode64(self)
      end

      def as_string(encoding)
        ::String.new(self, encoding: encoding).encode(encoding, invalid: :replace, undef: :replace)
      end

      def as_utf8
        as_string('utf-8')
      end

      def sha1
        Binary.new(::Digest::SHA1.digest(self))
      end

      private

      def summary
        if length.positive?
          left = "0x#{byteslice(0, SUMMARY_LENGTH).unpack1('H*')}"
          right = bytesize > SUMMARY_LENGTH ? "…(#{bytesize - SUMMARY_LENGTH} bytes more)" : ''
          "#{left}#{right}"
        else
          ''
        end
      end
    end
  end
end

String.prepend(Workato::Extension::String)
