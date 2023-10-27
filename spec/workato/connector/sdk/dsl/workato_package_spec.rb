# typed: false
# frozen_string_literal: true

module Workato::Connector::Sdk
  RSpec.describe Dsl::WorkatoPackage do
    subject(:package) { described_class.new(streams: streams, connection: connection) }

    let(:streams) { ProhibitedStreams.new }
    let(:connection) { Connection.new }

    shared_context 'with JWT' do
      let(:pem_key) do
        <<~PEM
          -----BEGIN RSA PRIVATE KEY-----
          MIIEogIBAAKCAQEAnzyis1ZjfNB0bBgKFMSvvkTtwlvBsaJq7S5wA+kzeVOVpVWw
          kWdVha4s38XM/pa/yr47av7+z3VTmvDRyAHcaT92whREFpLv9cj5lTeJSibyr/Mr
          m/YtjCZVWgaOYIhwrXwKLqPr/11inWsAkfIytvHWTxZYEcXLgAXFuUuaS3uF9gEi
          NQwzGTU1v0FqkqTBr4B8nW3HCN47XUu0t8Y0e+lf4s4OxQawWD79J9/5d3Ry0vbV
          3Am1FtGJiJvOwRsIfVChDpYStTcHTCMqtvWbV6L11BWkpzGXSW4Hv43qa+GSYOD2
          QU68Mb59oSk2OB+BtOLpJofmbGEGgvmwyCI9MwIDAQABAoIBACiARq2wkltjtcjs
          kFvZ7w1JAORHbEufEO1Eu27zOIlqbgyAcAl7q+/1bip4Z/x1IVES84/yTaM8p0go
          amMhvgry/mS8vNi1BN2SAZEnb/7xSxbflb70bX9RHLJqKnp5GZe2jexw+wyXlwaM
          +bclUCrh9e1ltH7IvUrRrQnFJfh+is1fRon9Co9Li0GwoN0x0byrrngU8Ak3Y6D9
          D8GjQA4Elm94ST3izJv8iCOLSDBmzsPsXfcCUZfmTfZ5DbUDMbMxRnSo3nQeoKGC
          0Lj9FkWcfmLcpGlSXTO+Ww1L7EGq+PT3NtRae1FZPwjddQ1/4V905kyQFLamAA5Y
          lSpE2wkCgYEAy1OPLQcZt4NQnQzPz2SBJqQN2P5u3vXl+zNVKP8w4eBv0vWuJJF+
          hkGNnSxXQrTkvDOIUddSKOzHHgSg4nY6K02ecyT0PPm/UZvtRpWrnBjcEVtHEJNp
          bU9pLD5iZ0J9sbzPU/LxPmuAP2Bs8JmTn6aFRspFrP7W0s1Nmk2jsm0CgYEAyH0X
          +jpoqxj4efZfkUrg5GbSEhf+dZglf0tTOA5bVg8IYwtmNk/pniLG/zI7c+GlTc9B
          BwfMr59EzBq/eFMI7+LgXaVUsM/sS4Ry+yeK6SJx/otIMWtDfqxsLD8CPMCRvecC
          2Pip4uSgrl0MOebl9XKp57GoaUWRWRHqwV4Y6h8CgYAZhI4mh4qZtnhKjY4TKDjx
          QYufXSdLAi9v3FxmvchDwOgn4L+PRVdMwDNms2bsL0m5uPn104EzM6w1vzz1zwKz
          5pTpPI0OjgWN13Tq8+PKvm/4Ga2MjgOgPWQkslulO/oMcXbPwWC3hcRdr9tcQtn9
          Imf9n2spL/6EDFId+Hp/7QKBgAqlWdiXsWckdE1Fn91/NGHsc8syKvjjk1onDcw0
          NvVi5vcba9oGdElJX3e9mxqUKMrw7msJJv1MX8LWyMQC5L6YNYHDfbPF1q5L4i8j
          8mRex97UVokJQRRA452V2vCO6S5ETgpnad36de3MUxHgCOX3qL382Qx9/THVmbma
          3YfRAoGAUxL/Eu5yvMK8SAt/dJK6FedngcM3JEFNplmtLYVLWhkIlNRGDwkg3I5K
          y18Ae9n7dHVueyslrb6weq7dTkYDi3iOYRW8HRkIQh06wEdbxt0shTzAJvvCQfrB
          jg/3747WSsf/zBTcHihTRBdAv6OmdhV4/dD5YBfLAkLrd+mX7iE=
          -----END RSA PRIVATE KEY-----
        PEM
      end

      let(:ecdsa_pem_key_mapping) do
        {
          'ES256' => <<~PEM,
            -----BEGIN EC PRIVATE KEY-----
            MHcCAQEEIEGBdceY2GlFegvvu/ojoRia8syLtzLkP9Krg3LdBEvdoAoGCCqGSM49
            AwEHoUQDQgAEvuHZk3TPnxnzNBQ0oqVNdR6BIYfzzNcCfhuzXObjvY8AwZDAVVgx
            DzI9rwcy8JOHt6RH5qCKmY0wqzCIkeFr0A==
            -----END EC PRIVATE KEY-----
          PEM
          'ES384' => <<~PEM,
            -----BEGIN EC PRIVATE KEY-----
            MIGkAgEBBDCTMLPkExlzV8B+kdCtb96g325Z3bIoPHOzBsTizoxafM5MCx59lRIU
            3qgn/sqAC3WgBwYFK4EEACKhZANiAAReDktimYHHqVHAscW8v02gD5QR2i6W5DQJ
            vhr0P9iJC/GLTDyxt8ddy2S5dXvZcn5xGdnBtDDYCqFsxH7vhQYWDb/8pWkvg9Q6
            CctLeDWsPPEP3BEm3pzqEbjhxEtscL4=
            -----END EC PRIVATE KEY-----
          PEM
          'ES512' => <<~PEM
            -----BEGIN EC PRIVATE KEY-----
            MIHcAgEBBEIAA8uZPCjTQtVwRLczD6fPAzj8JMjLLOmAcmFz323hYNR4LUAE1YWz
            8MAs68czur4ZqDMithxibrpMVTeoibODc8igBwYFK4EEACOhgYkDgYYABAGlaFT3
            vFeJcVozXV2Lp8OnyYNp10DDYz7b4azAR1orAdvt8atPm1UCVOhE2qFXHsdPh3Pe
            D+RxZ2KNI4LZF4LfCwDdjWnjxeFK5c/i5bhkIV7ysdC5e4D0eXMnXL3RVWPYaL5N
            a7k9945aVZ73st9MNLbi9sCGwgWm8P+ESN7q80gYPA==
            -----END EC PRIVATE KEY-----
          PEM
        }
      end

      let(:invalid_rsa_pem_key) do
        <<~PEM
          -----BEGIN RSA PUBLIC KEY-----
          MIICXQIBAAKBgQC2Mwqc9L0kjZ9MD09mpTIOw+xDrASEXNNyuaFdjkXDFAUGd3JM
          Cr1RnKq+Wiwuw7eAE6zrYXGdRdmmg8aGP8diaXUXXrpZl3PNly5NTEen6OmoD8JH
          C2FcQ2ndl7Pz6llayCM7I0PsuernD3Wh883BunXUbYLq
          -----END RSA PUBLIC KEY-----
        PEM
      end

      let(:mismatched_ecdsa_pem_key_mapping) do
        {
          'ES256' => <<~PEM,
            -----BEGIN EC PRIVATE KEY-----
            MHQCAQEEIPsK9XRM1HbQvIYioD7KALTmNDHEqsMkb7EalaqqkTJHoAcGBSuBBAAK
            oUQDQgAEVhc6D0OY0GqwQlto0h5iHUc1I1FumdYvJnMV37uee8u1xikHsTp1HGcY
            T7/OqXUhZTM1bD4bonb3tt7je8lgdQ==
            -----END EC PRIVATE KEY-----
          PEM
          'ES384' => <<~PEM
            -----BEGIN EC PRIVATE KEY-----
            MIGoAgEBBDA6RNBOLZ3aM9Pyu1Gu3fay9dnBVwR1vw+lJwcKyJ3DcXm+enSOLZtC
            W9yusF8J/9mgCwYJKyQDAwIIAQELoWQDYgAESDlU86jvIC9QkJ27UrwfMY0FQaoa
            uJVLJUfsqzbWa+JPu/QaRK99FgN0TOrv36hIBhtfsohYqFJcCHffnvJA1m1GRXDG
            EA74eMQJVbsTm/8BZjIgPrMD0ruqa8/cX6wr
            -----END EC PRIVATE KEY-----
          PEM
        }
      end

      let(:invalid_ecdsa_pem_key) do
        <<~PEM
          -----BEGIN EC PUBLIC KEY-----
          MHQCAQEEIPsK9XRM1HbQvIYioD7KALTmNDHEqsMkb7EalaqqkTJHoAcGBSuBBAAK
          oUQDQgAEVhc6D0OY0GqwQlto0h5iHUc1I1FumdYvJnMV37uee8u1xikHsTp1HGcY
          T7/OqXUhZTM1bD4bonb3tt7je8lgdQ==
          -----END EC PUBLIC KEY-----
        PEM
      end

      let(:payload) do
        {
          sub: '1234567890',
          name: 'John Doe',
          admin: true,
          iat: 1_516_239_022
        }
      end

      let(:header) do
        { typ: 'JWT' }
      end
    end

    describe '#jwt_encode' do
      include_context 'with JWT'

      let(:algorithm) { 'RS256' }

      let(:short_rsa_pem_key) do
        <<~PEM
          -----BEGIN RSA PRIVATE KEY-----
          MIICXQIBAAKBgQC2Mwqc9L0kjZ9MD09mpTIOw+xDrASEXNNyuaFdjkXDFAUGd3JM
          Cr1RnKq+Wiwuw7eAE6zrYXGdRdmmg8aGP8diaXUXXrpZl3PNly5NTEen6OmoD8JH
          Dh62V/hHMPiwl1oF43uiZTXsTANzWMN56mvOl3Kc8oZyX6bYvfhMwGN+bQIDAQAB
          AoGAYgjeugtZxlRJlURbpdBXOeijtNnW6F2GDKHjOJK36LpZ5dvZbR8ONN6GZLvi
          MBtxHgH4NgKNfmE6NkWLSWsB3YJbwr/NX8Hs3kAGSpiySYnsZTHHv9TzqnmqZOFs
          pCnQh/pwXKktBeL3OAMkDlEZebNukOGKyGcQ8nMwJLoVaOECQQDhoogmy4LFgo8S
          qEjD79v7ggMeUSfpfCTQARgf6lH2hzre7L/IOtdciLCNW5HI3QhgNBARBU8eHXIY
          LZzUgTLJAkEAzrgW9Pfhde9p2g+fF6iAWEEM+ym/K+1tgYM6OAmAWKvPTR+86rD3
          eb2LGj8AiYTDufQze9WVVii6AppnP/U8hQJBAJ+mI9XnW2Eq7tbRsaLJvYooxNIX
          tDjVeSqgC5TRdCsOJg6Dz3L6h1VW9i0e5HkORBXl4JRagE+boBYReA04WVkCQQCZ
          4rrcQ8doNwDSnvxs7TgV+t8B/jLdLZNubVUisBgGamgY3r6Q64pe6zYpJKtutBHM
          VTkaP4Y7LHhERdME7rfNAkAYPQ6buUdrqAjWRHn63x5fBx9/U6zZV7jfRV0KRIF5
          C2FcQ2ndl7Pz6llayCM7I0PsuernD3Wh883BunXUbYLq
          -----END RSA PRIVATE KEY-----
        PEM
      end

      let(:short_ecdsa_pem_key) do
        <<~PEM
          -----BEGIN EC PRIVATE KEY-----
          MD4CAQEEDjNJycrdEMSvcHlo/9VToAcGBSuBBAAGoSADHgAEn4+G/ofQhn/RPB+Z
          kUdjnrOfT8keQfiMetl3gw==
          -----END EC PRIVATE KEY-----
        PEM
      end

      let(:ecdsa_key_length_mapping) do
        {
          'ES256' => 256,
          'ES384' => 384,
          'ES512' => 521
        }
      end

      let(:expected_token) do
        'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9l' \
          'IiwiYWRtaW4iOnRydWUsImlhdCI6MTUxNjIzOTAyMn0.TCxMMDLgXOKzfY4r-RKVNYlXYqF02gBQbJinO4PRo' \
          'lwqNkKjB673JvgklhEtgYhctCbwl49l6xc69AEMXkCcujjO6y9dB1ALtTfMub9DxH7ow5QOGb_xXnBHDT5y79' \
          'beXN626Tbl3exuLuPwQbYNxwiDy9nQ36X1X0GjQTaP2psZwJhu0_Be4-UtUeuqOAn8R8nCvcVO8gpOJbqvGer' \
          'V4_NGAq-BgSH-Rv5dXyuLij2qsD_7f57ymenETKGPz5cdNMGa0YbndtCmHNwwOADWcqrYVSx6B-Y6SS1gkxI5' \
          'Uc6tPkdWHmQDNu8IqZyJftODHHGcpsQhzaPGJN02hdv9VA'
      end

      it { expect(package.jwt_encode(payload, pem_key, algorithm)).to eq(expected_token) }

      context 'when supported algorithms' do
        %w[RS256 RS384 RS512].each do |algorithm|
          context "when #{algorithm}" do
            it 'is not empty' do
              expect(package.jwt_encode(payload, pem_key, algorithm)).not_to be_empty
            end

            it 'is able to decode' do
              token = package.jwt_encode(payload, pem_key, algorithm)
              key = OpenSSL::PKey::RSA.new(pem_key)
              decoded_token = ::JWT.decode(token, key, true, { algorithm: algorithm })
              expect(decoded_token).to include(payload.with_indifferent_access)
            end

            it 'raises an error when encoding with a short RSA key' do
              expect { package.jwt_encode(payload, short_rsa_pem_key, algorithm) }.to raise_error(
                ArgumentError, 'A RSA key of size 2048 bits or larger MUST be used with JWT'
              )
            end

            it 'raises an error when encoding with an invalid RSA key' do
              expect { package.jwt_encode(payload, invalid_rsa_pem_key, algorithm) }.to raise_error(
                ArgumentError, 'Invalid key'
              )
            end
          end
        end

        %w[HS256 HS384 HS512].each do |algorithm|
          context "when #{algorithm}" do
            let(:hmac_secret) { 'my$ecretK3y' }

            it 'is not empty' do
              expect(package.jwt_encode(payload, hmac_secret, algorithm)).not_to be_empty
            end

            it 'is able to decode' do
              token = package.jwt_encode(payload, hmac_secret, algorithm)
              decoded_token = ::JWT.decode(token, hmac_secret, true, { algorithm: algorithm })
              expect(decoded_token).to include(payload.with_indifferent_access)
            end
          end
        end

        %w[ES256 ES384 ES512].each do |algorithm|
          context "when #{algorithm}" do
            it 'is not empty' do
              expect(package.jwt_encode(payload, ecdsa_pem_key_mapping[algorithm], algorithm)).not_to be_empty
            end

            it 'is able to decode' do
              token = package.jwt_encode(payload, ecdsa_pem_key_mapping[algorithm], algorithm)
              key = OpenSSL::PKey::EC.new(ecdsa_pem_key_mapping[algorithm])
              decoded_token = ::JWT.decode(token, key, true, { algorithm: algorithm })
              expect(decoded_token).to include(payload.with_indifferent_access)
            end

            it 'raises an error when encoding with a short key' do
              expect { package.jwt_encode(payload, short_ecdsa_pem_key, algorithm) }.to raise_error(
                ArgumentError, "An ECDSA key of size #{ecdsa_key_length_mapping[algorithm]} bits MUST be used with JWT"
              )
            end

            it 'raises an error when encoding with an invalid ECDSA key' do
              expect { package.jwt_encode(payload, invalid_ecdsa_pem_key, algorithm) }.to raise_error(
                ArgumentError, 'Invalid key'
              )
            end
          end
        end

        %w[ES256 ES384].each do |algorithm|
          context 'when ECDSA using mismatched curves' do
            it 'raises an error when encoding with mismatched algorithm and key' do
              expect { package.jwt_encode(payload, mismatched_ecdsa_pem_key_mapping[algorithm], algorithm) }
                .to raise_error(ArgumentError, 'Mismatched algorithm and key')
            end
          end
        end
      end

      context 'when unsupported algorithm' do
        let(:algorithm) { 'HS512256' }

        it 'raises error' do
          expect { package.jwt_encode(payload, pem_key, algorithm) }.to raise_error(
            ArgumentError,
            'Unsupported signing method. ' \
            "Supports only RS256, RS384, RS512, HS256, HS384, HS512, ES256, ES384, ES512. Got: 'HS512256'"
          )
        end
      end

      context 'with header' do
        let(:expected_token) do
          'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImtpZCI6IjkzNzIyNzQ5In0.eyJzdWIiOiIxMjM0NTY3ODkwIi' \
            'wibmFtZSI6IkpvaG4gRG9lIiwiYWRtaW4iOnRydWUsImlhdCI6MTUxNjIzOTAyMn0.c6S66GrBYVbPBUe3wZ1z' \
            'Wr2py0Cj0BnU2_uV2Eqq9aiz9Wb1dOtb5CNK-wb5hzWZUUDaYWOK0EOk5M4DmJKzTPaWWT76MxcWkCFAnNOah2' \
            'RllmiSvSPRVMgLwWCY9pIFCVB6md3og-63X1_rpsgzi-EbTsKStE55CyNz3AXB1UM2zqvKPhGHI1EbtyBSE86H' \
            'l1Gr9z6BvpCuwgOfi2HuCPEy_1a2-2Is6vLH6aivK4dyH0Ahpg898CrDYOziLXbFqrSbSDWQVMF_aLnwYTud7d' \
            'IR_7nGuBHb53CIUFMvtrNAk40zEQnVm6VxVg_XuMcQyUs2ZlnMBg5UkIoRopPBQA'
        end

        it { expect(package.jwt_encode(payload, pem_key, algorithm, kid: '93722749')).to eq(expected_token) }
      end

      context 'when RSA key is too weak' do
        let(:pem_key) do
          <<~RSA
            -----BEGIN RSA PRIVATE KEY-----
            MIICWwIBAAKBgQC81LXI3wGNqSXKiQj+3oLE0vX1hoE72/q68bDVOueS443j0Tnl
            buKGGGPY6C9MDZtLHZHgS0IjruUQPbppPKlIECsrKcE1jhj3a/tRyEXmgfyrPvbJ
            7hSSTzPL2zBEbTo31AaawIpR7SLXqxjaMgV7xURkMprtn4+ZRpsA56xPmwIDAQAB
            AoGANFpdFBYQHjB5U8/ueItEgkFjA/GIvwncWBxORLASKD2Cx1jozl2R3E/Czw6A
            nntfRNIr8Z2r9qy0wW370tWIsQHOqcYOJSwwTwPtopwfBtcjRPWSqtz/gMeroJPm
            ZT0xp42cq9kco+JMwUO1B7BBVmqUoxDMKYDeeF5zTERWCUECQQDt7pgnc59pU5Sn
            C2GhqNmaIhkMYVYeLT3S6pIPBfpJTYjdJD6j9AgeLqU8WCTkngsCFksfWxiSwai9
            Dn8U5TgrAkEAyyuWsLMm60tpwRFSYkWn6Yr+gM/jWLt82TZe+KxYPDrW7nviBKDs
            +c3aOl15AsX/WInZ/e3irH3IdGt41vGeUQJAbYdNQbQHKTxRjQg/PGT3Lu4Na9aP
            Bzs6X5KeBA5zZjUsEOjzcRQQfJxqcjn9WcSrOp26nUeZK028+LLoq1zNmwJAImkz
            kKIHSXrwYn7okTRzCB8+k9qiCvlWYAPRehTWrPzaQnJBCb+n43d2KsSCJnIamYhf
            n56W8dgsB2vcf6tUwQJAYQ/+rEjAe0MPleOAyypuMNeXsV9Oh/mUXo2itXzH1oOJ
            5bwjkc41QKIBLK96dyOMUjT5eby7sVPzogRhgbwabw==
            -----END RSA PRIVATE KEY-----
          RSA
        end

        it 'raises error' do
          expect { package.jwt_encode(payload, pem_key, algorithm) }.to raise_error(
            ArgumentError, 'A RSA key of size 2048 bits or larger MUST be used with JWT'
          )
        end
      end
    end

    describe '#jwt_encode_rs256' do
      it "is alias for jwt_encode( ..., 'RS256')" do
        expect(package).to receive(:jwt_encode).with({ a: 1 }, 'b', 'RS256', { c: :d }) # rubocop:disable RSpec/SubjectStub, RSpec/MessageSpies
        package.jwt_encode_rs256({ a: 1 }, 'b', { c: :d })
      end
    end

    describe '#jwt_decode' do
      include_context 'with JWT'

      context 'when supported algorithms' do
        %w[RS256 RS384 RS512].each do |algorithm|
          context "when #{algorithm}" do
            let(:key) { OpenSSL::PKey::RSA.new(pem_key) }
            let(:token) { ::JWT.encode(payload, key, algorithm, typ: 'JWT') }

            it 'is not empty' do
              expect(package.jwt_decode(token, pem_key, algorithm)).not_to be_empty
            end

            it 'decodes token' do
              decoded_token = package.jwt_decode(token, pem_key, algorithm)
              expect(decoded_token).to eq({
                payload: payload,
                header: header.merge(alg: algorithm)
              }.with_indifferent_access)
            end

            it 'raises an error when decoding with an invalid RSA key' do
              expect { package.jwt_decode(token, invalid_rsa_pem_key, algorithm) }.to raise_error(
                ArgumentError, 'Invalid key'
              )
            end
          end
        end

        %w[HS256 HS384 HS512].each do |algorithm|
          context "when #{algorithm}" do
            let(:hmac_secret) { 'my$ecretK3y' }
            let(:token) { ::JWT.encode(payload, hmac_secret, algorithm, typ: 'JWT') }

            it 'is not empty' do
              expect(package.jwt_decode(token, hmac_secret, algorithm)).not_to be_empty
            end

            it 'decodes token' do
              decoded_token = package.jwt_decode(token, hmac_secret, algorithm)
              expect(decoded_token).to eq({
                payload: payload,
                header: header.merge(alg: algorithm)
              }.with_indifferent_access)
            end
          end
        end

        %w[ES256 ES384 ES512].each do |algorithm|
          context "when #{algorithm}" do
            let(:key) { OpenSSL::PKey::EC.new(ecdsa_pem_key_mapping[algorithm]) }
            let(:token) { ::JWT.encode(payload, key, algorithm, typ: 'JWT') }

            it 'is not empty' do
              expect(package.jwt_decode(token, ecdsa_pem_key_mapping[algorithm], algorithm)).not_to be_empty
            end

            it 'decodes token' do
              decoded_token = package.jwt_decode(token, ecdsa_pem_key_mapping[algorithm], algorithm)
              expect(decoded_token).to eq({
                payload: payload,
                header: header.merge(alg: algorithm)
              }.with_indifferent_access)
            end

            it 'raises an error when decoding with an invalid ECDSA key' do
              expect { package.jwt_decode(token, invalid_ecdsa_pem_key, algorithm) }.to raise_error(
                ArgumentError, 'Invalid key'
              )
            end
          end
        end

        %w[ES256 ES384].each do |algorithm|
          context 'when ECDSA using mismatched curves' do
            let(:mismatched_key) { mismatched_ecdsa_pem_key_mapping[algorithm] }

            it 'raises an error when encoding with mismatched algorithm and key' do
              key = OpenSSL::PKey::EC.new(ecdsa_pem_key_mapping[algorithm])
              token = ::JWT.encode(payload, key, algorithm, typ: 'JWT')
              expect { package.jwt_decode(token, mismatched_key, algorithm) }.to raise_error(
                ArgumentError, 'Mismatched algorithm and key'
              )
            end
          end
        end
      end

      context 'when unsupported algorithm' do
        let(:algorithm) { 'HS512256' }

        it 'raises error' do
          token = ::JWT.encode(payload, pem_key, 'HS256', typ: 'JWT')
          expect { package.jwt_decode(token, pem_key, algorithm) }.to raise_error(
            ArgumentError,
            'Unsupported verification algorithm. ' \
            "Supports only RS256, RS384, RS512, HS256, HS384, HS512, ES256, ES384, ES512. Got: 'HS512256'"
          )
        end
      end

      context 'when decoding with an invalid signature' do
        it 'raises error' do
          token = ::JWT.encode(payload, pem_key, 'HS256', typ: 'JWT')
          expect { package.jwt_decode(token.chop, pem_key, 'HS256') }.to raise_error(
            ArgumentError, 'Invalid signature'
          )
        end
      end
    end

    describe '#parse_yaml' do
      it 'parses safe YAML' do
        yaml_string = <<~YAML
          ---
          first_name: John
          last_name: Smith
        YAML

        expected_hash = {
          'first_name' => 'John',
          'last_name' => 'Smith'
        }

        expect(package.parse_yaml(yaml_string)).to eq(expected_hash)
      end

      it 'does not parse not safe YAML' do
        yaml_string = <<~YAML
          --- !ruby/struct
          foo: 1
          bar: 2
        YAML

        expect { package.parse_yaml(yaml_string) }.to raise_error(
          ArgumentError, 'YAML Parsing error. Tried to load unspecified class: Struct'
        )
      end
    end

    describe '#render_yaml' do
      it 'renders to YAML' do
        hash = {
          'first_name' => 'John',
          'last_name' => 'Smith'
        }

        expected_yaml_string = <<~YAML
          ---
          first_name: John
          last_name: Smith
        YAML

        expect(package.render_yaml(hash)).to eq(expected_yaml_string)
      end
    end

    describe '#random_bytes' do
      it 'random bytes' do
        allow(::OpenSSL::Random).to receive(:random_bytes).and_return('00000000')
        expect(package.random_bytes(8)).to eq('00000000')
      end

      it 'random bytes exception' do
        expect { package.random_bytes(33) }.to raise_error(
          ArgumentError, 'The requested length or random bytes sequence should be <= 32'
        )
      end
    end

    describe '#uuid' do
      it 'uuid correct format' do
        expect(package.uuid).to match(/.{8}-.{4}-.{4}-.{4}-.{12}/)
      end
    end

    describe '#pbkdf2' do
      let(:password) { 'password' }
      let(:salt) { 'salt' }
      let(:p_base64) { 'boi+i61+rp2eEKoGEiQDTw==' }
      let(:p_base64_two) { 'YVVWHTpGS+i08UVoEBx+DQ==' }

      it 'generates key' do
        p = package.pbkdf2_hmac_sha1(password, salt)
        expect(p.base64).to eq(p_base64)
        expect(p.bytesize).to eq(16)
        p_2k_iterations = package.pbkdf2_hmac_sha1(password, salt, 2000)
        expect(p_2k_iterations.base64).to eq(p_base64_two)
        p_8bytes = package.pbkdf2_hmac_sha1(password, salt, 1000, 8)
        expect(p_8bytes.bytesize).to eq(8)
      end
    end

    describe '#aes' do
      let(:text) { 'text' }
      let(:password) { 'passworddrowssap' }
      let(:wrong_password) { 'passwordpassword' }
      let(:encrypted_base64) { 'RFAoE6vXAuZ4oSFWykFAeg==' }
      let(:encrypted_base64_two) { 'YkNa+r8NozAAsCeI4CFGJg==' }
      let(:iv16) { 'init_vector00000' }
      let(:auth_data) { 'additional' }

      it 'encrypts string correctly' do
        # 128 bit key
        encrypted = package.aes_cbc_encrypt(text, password)
        expect(encrypted.binary?).to be(true)
        expect(encrypted.base64).to eq(encrypted_base64)
      end

      it 'decrypts string correctly' do
        decrypted = package.aes_cbc_decrypt(Base64.decode64(encrypted_base64), password)
        expect(decrypted.binary?).to be(true)
        expect(Base64.decode64(decrypted.base64)).to eq(text)
      end

      it 'encrypts string correctly 2' do
        # 256 bit key
        encrypted = package.aes_cbc_encrypt(text, password * 2)
        expect(encrypted.binary?).to be(true)
        expect(encrypted.base64).to eq(encrypted_base64_two)
      end

      it 'decrypts string correctly 2' do
        decrypted = package.aes_cbc_decrypt(Base64.decode64(encrypted_base64_two), password * 2)
        expect(decrypted.binary?).to be(true)
        expect(Base64.decode64(decrypted.base64)).to eq(text)
      end

      it 'encrypt/decrypts with init vector' do
        encrypted = package.aes_cbc_encrypt(text, password, iv16)
        expect(package.aes_cbc_decrypt(encrypted, password, iv16)).to eq(text)
      end

      context 'when decryption fails with OpenSSL::Cipher::CipherError' do
        it 'wraps native error with Sdk::Error' do
          encrypted = package.aes_cbc_encrypt(text, password)
          expect { package.aes_cbc_decrypt(encrypted, wrong_password) }.to raise_error(ArgumentError, 'bad decrypt')
        end
      end
    end

    describe '#verify_rsa' do
      subject(:verify_rca) { package.verify_rsa(payload, certificate, signature) }

      let(:signature) do
        Workato::Types::Binary.new(
          ::Base64.decode64(
            'M+p2y+jy1/Gtdl5FhNPzPcy9SAjF9H7P1G001qLrCmfAH8dDPBnaa4dEUTwi+84XPPydN3F+mbTvdyBk33Pjj045szFI6ZVjyhZRtD3x' \
            'lOjnAkOOe5njughJn5G8A6pMLK8N86qNDJ5lRB0egA00y3FWY5h+wa65H1egJWMeZuBrii5AHmMmRg2QFdimc5bxFuRsQxKVRKbh8ZXm' \
            'ofSlvWwhhGesr+zq+oKIvDPakMu8Hi1f9qFMwT0GGJ/GUsmugJO5vOLL8G8aCV/XsfpHoDNNIgs6/TZ/gXcWKmI8j9mUPLf1inpKTj7X' \
            'EGF0S+XaY+JjeWBMNLlMe7lXHjc3/Q=='
          )
        )
      end
      let(:certificate) do
        <<~RCA
          -----BEGIN CERTIFICATE-----
          MIIDxzCCAq8CFELj6xaTPD+SRVzR1h1gTOAgF5RGMA0GCSqGSIb3DQEBDQUAMIGf
          MQswCQYDVQQGEwJVUzETMBEGA1UECAwKQ2FsaWZvcm5pYTEWMBQGA1UEBwwNTW91
          bnRhaW4gVmlldzEQMA4GA1UECgwHV29ya2F0bzEPMA0GA1UECwwGRGV2b3BzMR0w
          GwYDVQQDDBRUZXN0IFJvb3QgU2VydmVycyBDQTEhMB8GCSqGSIb3DQEJARYSZGV2
          b3BzQHdvcmthdG8uY29tMB4XDTIwMDQwMjAwMzU1OVoXDTMwMDMzMTAwMzU1OVow
          gZ8xCzAJBgNVBAYTAlVTMRMwEQYDVQQIDApDYWxpZm9ybmlhMRYwFAYDVQQHDA1N
          b3VudGFpbiBWaWV3MRAwDgYDVQQKDAdXb3JrYXRvMQ8wDQYDVQQLDAZEZXZvcHMx
          HTAbBgNVBAMMFFRlc3QgUm9vdCBTZXJ2ZXJzIENBMSEwHwYJKoZIhvcNAQkBFhJk
          ZXZvcHNAd29ya2F0by5jb20wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
          AQDEdEzr3QasXorEL+BikGRF05K8fSbq6SVIh1tsEY0et0IRJJdcmrGvO+J6+k6y
          A+B3csAAj07XLNUYJbxRh4imMS2r1pKoBNrGPfa6rGygHKfTPXV8sSxPEYpp4m+O
          Z9oVakPbCK4v8mRCm4+x+1e0Isy7tAUhHqQDJ7efJMNM4keFyhPzFG4CvEA6SXEF
          fUWUO6kL6K51Wi2xQQEMyxAeinzt+EXe4W3E+Il70ewjBT0yuQVhU3K25Rn4u4K7
          F6CxPoUybAm52hZRMtVEG0Hsb+T3dbxh3G8T1j12kkUwsqXLQhU946iq5YL4WCnO
          oDXUxGkg248PzkwVZZgnvtJZAgMBAAEwDQYJKoZIhvcNAQENBQADggEBAIKTAbki
          jb2KPPS9X4Vs/BRzxWPmekmxBlwWH75NTpQecL8Hj1TOwsX+Mso1Mn1G/aSoq9Uu
          lBV4ETaxTltbbZKKwBKluRgjzk6plsgNCwZo8YJmn/bsZnFM1oJ/8BqPNgQVVefh
          CzlWvHFETZLLi77CSqmEHElwrdLjI1sfmA1AXb+YPJjhcQyr8Pi8FnvJpvekQxVL
          O48My6VNotBurhTXzmWkmtY4ogepPuJUA+utJPtTraCQoKnsE+uHv5tmQO1zVm12
          GUGe2XGtoXDmcf1UCVpZS6fckfkRVmoOYaTWkG4LIuugvZr07pu+tcJOXlds8QmV
          1xXCSzvBvtRZYAU=
          -----END CERTIFICATE-----
        RCA
      end
      let(:payload) { 'abc' }

      it { is_expected.to equal(true) }

      context 'when unsupported method' do
        subject(:verify_rca) { package.verify_rsa(payload, certificate, signature, 'HS256') }

        it { expect { verify_rca }.to raise_error(ArgumentError, /Unsupported signing method/) }
      end

      context 'when wrong signature method' do
        let(:signature) { 'incorrect' }

        it { is_expected.to equal(false) }
      end

      context 'when invalid certificate' do
        let(:certificate) { 'incorrect' }

        it { expect { verify_rca }.to raise_error(ArgumentError, 'Invalid certificate format') }
      end
    end
  end
end
