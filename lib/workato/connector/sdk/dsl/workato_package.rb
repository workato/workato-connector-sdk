# typed: true
# frozen_string_literal: true

require 'jwt'
require_relative './csv_package'
require_relative './stream_package'

using Workato::Extension::HashWithIndifferentAccess

module Workato
  module Connector
    module Sdk
      module Dsl
        class WorkatoPackage
          JWT_ALGORITHMS = %w[RS256 RS384 RS512].freeze
          JWT_RSA_KEY_MIN_LENGTH = 2048

          VERIFY_RCA_ALGORITHMS = %w[SHA SHA1 SHA224 SHA256 SHA384 SHA512].freeze

          def initialize(streams:, connection:)
            @streams = streams
            @connection = connection
          end

          def jwt_encode_rs256(payload, key, header_fields = {})
            jwt_encode(payload, key, 'RS256', header_fields)
          end

          def jwt_encode(payload, key, algorithm, header_fields = {})
            algorithm = algorithm.to_s.upcase
            unless JWT_ALGORITHMS.include?(algorithm)
              raise "Unsupported signing method. Supports only #{JWT_ALGORITHMS.join(', ')}. Got: '#{algorithm}'"
            end

            rsa_private = OpenSSL::PKey::RSA.new(key)
            if rsa_private.n.num_bits < JWT_RSA_KEY_MIN_LENGTH
              raise "A RSA key of size #{JWT_RSA_KEY_MIN_LENGTH} bits or larger MUST be used with JWT."
            end

            header_fields = HashWithIndifferentAccess.wrap(header_fields).except(:typ, :alg)
            ::JWT.encode(payload, rsa_private, algorithm, header_fields)
          end

          def verify_rsa(payload, certificate, signature, algorithm = 'SHA256')
            algorithm = algorithm.to_s.upcase
            unless VERIFY_RCA_ALGORITHMS.include?(algorithm)
              raise "Unsupported signing method. Supports only #{VERIFY_RCA_ALGORITHMS.join(', ')}. Got: '#{algorithm}'"
            end

            cert = OpenSSL::X509::Certificate.new(certificate)
            digest = OpenSSL::Digest.new(algorithm)
            cert.public_key.verify(digest, signature, payload)
          rescue OpenSSL::PKey::PKeyError
            raise 'An error occurred during signature verification. Check arguments'
          rescue OpenSSL::X509::CertificateError
            raise 'Invalid certificate format'
          end

          def parse_yaml(yaml)
            ::Psych.safe_load(yaml)
          rescue ::Psych::DisallowedClass => e
            raise e.message
          end

          def render_yaml(obj)
            ::Psych.dump(obj)
          end

          def parse_json(source)
            JSON.parse(source)
          rescue JSON::ParserError => e
            raise JSONResponseFormatError, e
          end

          def uuid
            SecureRandom.uuid
          end

          RANDOM_SIZE = 32

          def random_bytes(len)
            unless (len.is_a? ::Integer) && (len <= RANDOM_SIZE)
              raise "The requested length or random bytes sequence should be <= #{RANDOM_SIZE}"
            end

            Types::Binary.new(::OpenSSL::Random.random_bytes(len))
          end

          ALLOWED_KEY_SIZES = [128, 192, 256].freeze

          def aes_cbc_encrypt(string, key, init_vector = nil)
            key_size = key.bytesize * 8
            unless ALLOWED_KEY_SIZES.include?(key_size)
              raise 'Incorrect key size for AES'
            end

            cipher = ::OpenSSL::Cipher.new("AES-#{key_size}-CBC")
            cipher.encrypt
            cipher.key = key
            cipher.iv = init_vector if init_vector.present?
            Types::Binary.new(cipher.update(string) + cipher.final)
          end

          def aes_cbc_decrypt(string, key, init_vector = nil)
            key_size = key.bytesize * 8
            unless ALLOWED_KEY_SIZES.include?(key_size)
              raise 'Incorrect key size for AES'
            end

            cipher = ::OpenSSL::Cipher.new("AES-#{key_size}-CBC")
            cipher.decrypt
            cipher.key = key
            cipher.iv = init_vector if init_vector.present?
            Types::Binary.new(cipher.update(string) + cipher.final)
          end

          def pbkdf2_hmac_sha1(string, salt, iterations = 1000, key_len = 16)
            Types::Binary.new(::OpenSSL::PKCS5.pbkdf2_hmac_sha1(string, salt, iterations, key_len))
          end

          def csv
            @csv ||= CsvPackage.new
          end

          def stream
            @stream ||= StreamPackage.new(streams: streams, connection: connection)
          end

          private

          def method_missing(symbol, *_args)
            raise UndefinedStdLibMethodError.new(symbol.to_s, 'workato')
          end

          def respond_to_missing?(*)
            false
          end

          attr_reader :streams

          attr_reader :connection
        end
      end
    end
  end
end
