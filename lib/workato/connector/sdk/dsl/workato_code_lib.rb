# frozen_string_literal: true

require 'jwt'

module Workato
  module Connector
    module Sdk
      module Dsl
        module WorkatoCodeLib
          JWT_ALGORITHMS = %w[RS256 RS384 RS512].freeze
          JWT_RSA_KEY_MIN_LENGTH = 2048

          def workato
            WorkatoCodeLib
          end

          def parse_json(source)
            WorkatoCodeLib.parse_json(source)
          end

          class << self
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

              header_fields = header_fields.present? ? header_fields.with_indifferent_access.except(:typ, :alg) : {}
              ::JWT.encode(payload, rsa_private, algorithm, header_fields)
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
            end

            def uuid
              SecureRandom.uuid
            end

            RANDOM_SIZE = 32

            def random_bytes(len)
              unless (len.is_a? ::Integer) && (len <= RANDOM_SIZE)
                raise "The requested length or random bytes sequence should be <= #{RANDOM_SIZE}"
              end

              Extension::Binary.new(::OpenSSL::Random.random_bytes(len))
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
              Extension::Binary.new(cipher.update(string) + cipher.final)
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
              Extension::Binary.new(cipher.update(string) + cipher.final)
            end

            def pbkdf2_hmac_sha1(string, salt, iterations = 1000, key_len = 16)
              Extension::Binary.new(::OpenSSL::PKCS5.pbkdf2_hmac_sha1(string, salt, iterations, key_len))
            end
          end
        end
      end
    end
  end
end
