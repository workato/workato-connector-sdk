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

      def binary?
        warn <<~WARNING
          WARNING: Ambiguous use of `String#binary?' method.
          For correct behavior of `binary?` method use explicit Workato::Types::UnicodeString for input strings and Workato::Types::Binary for input binaries
          See: https://www.rubydoc.info/gems/workato-connector-sdk/Workato/Types
        WARNING
        encoding == Encoding::ASCII_8BIT
      end

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
        Rails::Html::Sanitizer.full_sanitizer.new.sanitize(self)
      end

      def to_time(form = :local, format: nil)
        if format.present?
          format = HUMAN_DATE_FORMAT[format] if HUMAN_DATE_FORMAT.key?(format)
          time = ::Time.strptime(self, format)
          form == :utc ? time.utc : time.getlocal
        else
          super(form)
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
        I18n.transliterate(self, replacement: replacement)
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

      def +(other)
        Kernel.raise Workato::Connector::Sdk::ArgumentError, 'Cannot concatenate string with nil' if other.nil?

        super(other.to_s)
      end

      def to_hex
        unpack('H*')[0]
      end

      def base64
        encode_base64
      end

      alias encode_hex to_hex

      def decode_hex
        Types::Binary.new([self].pack('H*'))
      end

      def encode_base64
        Base64.strict_encode64(self)
      end

      def decode_base64
        Types::Binary.new(Base64.decode64(self))
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
        Types::Binary.new(Base64.urlsafe_decode64(self))
      end

      def encode_sha256
        Types::Binary.new(::Digest::SHA256.digest(self))
      end

      def encode_sha512
        Types::Binary.new(::Digest::SHA512.digest(self))
      end

      def encode_sha512_256 # rubocop:disable Naming/VariableNumber
        digest = ::OpenSSL::Digest.new('sha512-256', self)
        Types::Binary.new(digest.to_s)
      end

      def hmac_sha256(key)
        assert_string_argument!(key, 'key')

        digest = ::OpenSSL::Digest.new('sha256')
        Types::Binary.new(::OpenSSL::HMAC.digest(digest, key, self))
      end

      def hmac_sha512(key)
        assert_string_argument!(key, 'key')

        digest = ::OpenSSL::Digest.new('sha512')
        Types::Binary.new(::OpenSSL::HMAC.digest(digest, key, self))
      end

      def rsa_sha256(key)
        assert_string_argument!(key, 'key')

        digest = ::OpenSSL::Digest.new('sha256')
        private_key = ::OpenSSL::PKey::RSA.new(key)
        Types::Binary.new(private_key.sign(digest, self))
      end

      def rsa_sha512(key)
        assert_string_argument!(key, 'key')

        digest = ::OpenSSL::Digest.new('sha512')
        private_key = ::OpenSSL::PKey::RSA.new(key)
        Types::Binary.new(private_key.sign(digest, self))
      rescue OpenSSL::PKey::RSAError => e
        Kernel.raise(Workato::Connector::Sdk::ArgumentError, e.message)
      end

      def md5_hexdigest
        ::Digest::MD5.hexdigest(self)
      end

      def sha1
        Types::Binary.new(::Digest::SHA1.digest(self))
      end

      def hmac_sha1(key)
        assert_string_argument!(key, 'key')

        digest = ::OpenSSL::Digest.new('sha1')
        Types::Binary.new(::OpenSSL::HMAC.digest(digest, key, self))
      end

      def hmac_md5(key)
        assert_string_argument!(key, 'key')

        digest = ::OpenSSL::Digest.new('md5')
        Types::Binary.new(::OpenSSL::HMAC.digest(digest, key, self))
      end

      def from_xml
        Workato::Utilities::Xml.parse_xml_to_hash(self)
      end

      private

      def assert_string_argument!(value, arg_name)
        return if value.is_a?(String)

        Kernel.raise(
          Workato::Connector::Sdk::ArgumentError,
          "Expected a String for '#{arg_name}' parameter, given #{value.class.name}"
        )
      end
    end
  end
end

String.prepend(Workato::Extension::String)
