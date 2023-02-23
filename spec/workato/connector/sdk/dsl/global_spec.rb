# typed: false
# frozen_string_literal: true

module Workato::Connector::Sdk
  RSpec.describe Dsl::Global do
    let(:subject_class) do
      Class.new do
        include Dsl::Global
      end
    end

    subject(:workato) do
      subject_class.new
    end

    describe 'encrypt/decrypt' do
      subject(:decrypted_text) { workato.decrypt(workato.encrypt(text, key), key) }

      let(:text) { 'hello' }
      let(:key) { 'secret t0ken' }

      it { is_expected.to eq(text) }

      context 'when key is invalid' do
        subject(:decrypted_text) { workato.decrypt(workato.encrypt(text, key), 'invalid') }

        it 'raises invalid key error' do
          expect { decrypted_text }.to raise_error(%r{invalid/corrupt input or key})
        end
      end

      context 'when encrypted message is corrupted' do
        subject(:decrypted_text) { workato.decrypt('invalid', key) }

        it 'raises invalid input error' do
          expect { decrypted_text }.to raise_error(%r{invalid/corrupt input})
        end
      end
    end
  end
end
