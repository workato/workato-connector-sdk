# typed: false
# frozen_string_literal: true

RSpec.describe Workato::Utilities::Encoding do
  describe '.force_best_encoding!' do
    subject(:best_encoding) { encoded_string.encoding.name }

    let(:encoded_string) { described_class.force_best_encoding!(string) }

    context 'when binary' do
      let(:string) { "\xFF\xD8\xFF\xE0\x00\x10JFIF\x00\x01\x01\x01\x00H\x00H".dup }

      it { is_expected.to eq('ASCII-8BIT') }
    end

    context 'when ASCII' do
      let(:string) { 'abc'.encode('ASCII') }

      it { is_expected.to eq('UTF-8') }
    end

    context 'when non-latin' do
      let(:string) { 'АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧЩЩЪЫЬЭЮЯабвгдеёжзиклмнопрстуфхцчшщъыьэюя'.encode('KOI8-R') }

      it { is_expected.to eq('KOI8-R') }
    end

    context 'when binary vs. non-binary' do
      let(:string) { String.new('SAMEORIGIN', encoding: Encoding::ASCII_8BIT).dup }

      it { is_expected.to match(/ISO-8859-[1,2]/) }
    end

    context 'when false 1252' do
      # string that pretends to be valid (valid_encoding? - true )
      let(:string) { 129.chr.force_encoding(Encoding::WINDOWS_1252) }

      it { is_expected.to eq('Windows-1252') }
      it { expect(encoded_string).to eq('?') }
    end

    context 'when binary with 1252 similarity' do
      let(:string) { 129.chr.force_encoding(Encoding::BINARY) }

      it { is_expected.to eq('ASCII-8BIT') }
      it { expect(encoded_string).to eq(129.chr) }
    end
  end
end
