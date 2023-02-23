# typed: false
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
        let(:input) { Workato::Types::Binary.new("test\n") }

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
        let(:input) { Workato::Types::Binary.new('abc') }

        it { is_expected.to eq(expected_hmac_sha256) }
      end
    end

    describe '#to_date' do
      subject(:to_date) { input.to_date(format: format).to_s }

      let(:input) { '24/12/2014 10:30PM' }
      let(:format) { nil }
      let(:expected_date) { '2014-12-24' }

      it { is_expected.to eq(expected_date) }

      context 'when custom date format' do
        let(:input) { '12/24/2014 10:30PM' }
        let(:format) { 'MM/DD/YYYY' }

        it { is_expected.to eq(expected_date) }
      end

      context 'when unknown format' do
        let(:input) { '12/24/2014 10:30PM' }

        it { expect { to_date }.to raise_error(ArgumentError, 'invalid date') }
      end
    end

    describe '#to_time' do
      subject(:to_time) { input.to_time.strftime('%Y-%m-%dT%H:%M:%S%z') }

      [
        '2021-12-22T00:00:00.000000-00:00',
        '2021-12-22T05:00:00.000000-10:00',
        '2021-12-22T08:00:00.000000+04:00'
      ].each do |string|
        context "when #{string}" do
          let(:input) { string }
          let(:expected_time) { input.in_time_zone('UTC').strftime('%Y-%m-%dT%H:%M:%S%z') }

          it { is_expected.to eq(expected_time) }
        end
      end
    end

    describe '#from_xml' do
      subject(:from_xml) do
        '<?xml version="1.0" encoding="UTF-8"?> <hash id="add"><foo type="integer" id="v">1</foo></hash>'.from_xml
      end

      it 'parses' do
        expect(from_xml).to eq(
          { 'hash' => [{ '@id' => 'add', 'foo' => [{ '@id' => 'v', '@type' => 'integer', 'content!' => '1' }] }] }
        )
      end
    end

    describe '#strip_tags' do
      subject(:strip_tags) { '<script>var a=10;</script><div>foo</div><br></div><div>'.strip_tags }

      it { is_expected.to eq('foo') }
    end

    describe '#transliterate' do
      subject(:transliterate) { 'Chloé'.transliterate }

      it { is_expected.to eq('Chloe') }
    end

    describe '#quote' do
      subject(:quote) { "Paula's Baked Goods".quote }

      it { is_expected.to eq("Paula''s Baked Goods") }
    end

    describe '"SGVsbG8=".decode_base64.to_hex' do
      subject(:formula) { 'SGVsbG8='.decode_base64.to_hex }

      it { is_expected.to eq('48656c6c6f') }
    end

    describe '"hello".encode_hex.decode_hex.as_utf8' do
      subject(:formula) { 'hello'.encode_hex.decode_hex.as_utf8 }

      it { is_expected.to eq('hello') }
    end

    describe '"DABBAD00".decode_hex' do
      subject(:formula) { 'DABBAD00'.decode_hex.to_json }

      it { is_expected.to eq('0xdabbad00') }
    end

    describe '"Hello".encode_base64' do
      subject(:formula) { 'Hello'.encode_base64 }

      it { is_expected.to eq('SGVsbG8=') }
    end

    describe 'encode_urlsafe_base64' do
      subject(:formula) { 'ab>cd?'.encode_urlsafe_base64 }

      it { is_expected.to eq('YWI-Y2Q_') }
    end

    describe '"SGVsbG8=".decode_base64' do
      subject(:formula) { 'SGVsbG8='.decode_base64.to_json }

      it { is_expected.to eq('0x48656c6c6f') }
    end

    describe 'decode_urlsafe_base64' do
      subject(:formula) { '-__-'.decode_urlsafe_base64.to_json }

      it { is_expected.to eq('0xfbfffe') }
    end

    describe '"SGVsbG8=".decode_base64.as_string("utf-8")' do
      subject(:formula) { 'SGVsbG8='.decode_base64.as_string('utf-8') }

      it { is_expected.to eq('Hello') }
    end

    describe '"SGVsbG8=".decode_base64.as_utf8' do
      subject(:formula) { 'SGVsbG8='.decode_base64.as_utf8 }

      it { is_expected.to eq('Hello') }
    end

    describe '"Hello".encode_sha256' do
      subject(:formula) { 'Hello'.encode_sha256.to_json }

      it { is_expected.to eq('0x185f8db32271fe25f561a6fc938b2e264306ec304eda518007d1764826381969') }
    end

    describe '"Hello".md5_hexdigest' do
      subject(:formula) { 'Hello'.md5_hexdigest }

      it { is_expected.to eq(Digest::MD5.hexdigest('Hello')) }
    end

    describe '#hmac_md5' do
      subject(:hmac_md5) { 'what do ya want for nothing?'.hmac_md5('Jefe').unpack1('H*') }

      it { is_expected.to eq('750c783e6ab0b503eaa86e310a5db738') }
    end

    describe '#sha1' do
      subject(:sha1) { input.sha1.base64 }

      let(:input) { 'abcdef' }

      it { is_expected.to eq('H4rBDyPFtbwRZ72oS4M+XAV6d9I=') }

      context 'when empty string' do
        let(:input) { '' }

        it { is_expected.to eq('2jmj7l5rSw0yVb/vlWAYkK/YBwk=') }
      end

      context 'when binary string' do
        let(:input) { 'abcdef'.sha1 }

        it { is_expected.to eq('wtJNyjjp6GIJi4W/CrNcqlKAN5c=') }
      end
    end

    describe '#hmac_sha1' do
      subject(:hmac_sha1) { ''.hmac_sha1('').unpack1('H*') }

      it { is_expected.to eq('fbdb1d1b18aa6c08324b7d64b71fb76370690e1d') }
    end

    describe '#hmac_sha512' do
      subject(:hmac_sha512) { ''.hmac_sha512('').unpack1('H*') }

      it { is_expected.to eq('b936cee86c9f87aa5d3c6f2e84cb5a4239a5fe50480a6ec66b70ab5b1f4ac6730c6c515421b327ec1d69402e53dfb49ad7381eb067b338fd7b0cb22247225d47') } # rubocop:disable Layout/LineLength
    end

    describe 'is_number?' do
      subject(:is_number) { string.is_number? }

      let(:string) { '10.42' }

      it { is_expected.to be_truthy }

      context 'when empty' do
        let(:string) { '' }

        it { is_expected.to be_falsey }
      end

      context 'when text' do
        let(:string) { 'foo' }

        it { is_expected.to be_falsey }
      end
    end
  end
end
