# typed: false
# frozen_string_literal: true

module Workato::Connector::Sdk
  RSpec.describe Dsl::CsvPackage do
    subject(:package) { described_class.new }

    describe '.parse' do
      subject(:parse) { package.parse(csv, headers: true) }

      let(:csv) do
        <<~CSV
          color,size
          red,1
          green,2
        CSV
      end

      it { is_expected.to eq([{ 'color' => 'red', 'size' => '1' }, { 'color' => 'green', 'size' => '2' }]) }

      context 'when no headers' do
        subject(:parse) { package.parse(csv) }

        it { expect { parse }.to raise_error(/missing keyword: :?headers/) }
      end

      context 'when file is too big' do
        before do
          stub_const("#{described_class.name}::MAX_FILE_SIZE_FOR_PARSE", 10.bytes)
        end

        it 'fails with error' do
          expect { parse }.to raise_error(
            Workato::Connector::Sdk::CsvFileTooBigError,
            'CSV file is too big. Max allowed: 10 Bytes, got: 25 Bytes'
          )
        end
      end

      context 'when file is too long' do
        before do
          stub_const("#{described_class.name}::MAX_LINES_FOR_PARSE", 1)
        end

        it 'fails with error' do
          expect { parse }.to raise_error(
            Workato::Connector::Sdk::CsvFileTooManyLinesError,
            'CSV file has too many lines. Max allowed: 1'
          )
        end
      end

      context 'when argument is invalid' do
        subject(:parse) { package.parse(csv, headers: true, quote_char: 'foo') }

        it 'fails with error' do
          expect { parse }.to raise_error(/:quote_char has to be( nil or)? a single character String/)
        end
      end

      context 'when CSV formatting is invalid' do
        let(:csv) { '"1,2,3' }

        it 'fails with error' do
          expect { parse }.to raise_error(
            Workato::Connector::Sdk::CsvFormatError,
            match(/Unclosed quoted field .n line 1\./)
          )
        end
      end

      context 'when skip first line' do
        subject(:parse) { package.parse(csv, headers: %w[COLOR SIZE], skip_first_line: true) }

        it { is_expected.to eq([{ 'COLOR' => 'red', 'SIZE' => '1' }, { 'COLOR' => 'green', 'SIZE' => '2' }]) }
      end
    end

    describe 'when undefined method' do
      it 'raises user-friendly error' do
        expect { package.foo }.to raise_error("Undefined method 'foo' for \"workato.csv\" namespace")
      end
    end
  end
end
