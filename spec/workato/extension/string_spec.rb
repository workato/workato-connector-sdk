# frozen_string_literal: true

module Workato::Extension
  RSpec.describe String do
    describe '#rsa_sha256' do
      let(:input) { "test\n" }
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
      let(:expected_base64) do
        <<~BASE64.gsub("\n", '')
          cKlVh/wxo36lpPt78mmW3sud8T/WT2UyyJNuujjxPmW81xiCffwm/Quu1B65JEuj
          mHQnXD01mkuX1K9iQJ5heFyir2Lh9zvoU8AsgEfAGO1Z73X8zCj2qnD+k2mwZJFN
          xd4GBJokowROMXcF5Rk2QEx8k/LTa6NkO85zCj6a+QuArRXhthSFHQcCm+T8zQA4
          sSukaEAUnNccnpKfphZoq/0xvCDg21vvt+XXVBm96kEGXGcnii7FBaGT/dbYCnr7
          Y2AKO/m5vjvs2FilBJo8Oxl8BCC7D4tDBX5TV0yoB+B57Ygupcx/jfJItdKUAZxQ
          lzo4fJoU2STRB6kYuVwdjQ==
        BASE64
      end

      it 'signs a string correctly' do
        expect(input.rsa_sha256(pem_key).base64).to eq(expected_base64)
      end

      context 'when binary input' do
        let(:input) { Binary.new("test\n") }

        it 'signs a binary correctly' do
          expect(input.rsa_sha256(pem_key).base64).to eq(expected_base64)
        end
      end
    end

    describe '#hmac_sha256' do
      subject(:hmac_sha256) { input.hmac_sha256(key).to_json }

      let(:input) { 'abc' }
      let(:key) { '$ecRet' }
      let(:expected_hmac_sha256) { '0xb37699f713c0317d93a13f2fdd648957a21e30acfc36e541c455a3160d196e6d' }

      it { is_expected.to eq(expected_hmac_sha256) }

      context 'when binary input' do
        let(:input) { Binary.new('abc') }

        it { is_expected.to eq(expected_hmac_sha256) }
      end
    end
  end
end
