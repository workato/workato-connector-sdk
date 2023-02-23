# typed: false
# frozen_string_literal: true

module Workato::Connector::Sdk
  RSpec.describe LookupTables do
    before(:all) do
      described_class.load_data(lookup_table_data)
      described_class.from_yaml('spec/fixtures/lookup_tables.yaml')
      described_class.from_csv(8, 'Table 8', 'spec/fixtures/lookup_table.csv')
    end

    subject(:lookup) { described_class.lookup(table_name, conditions) }

    let(:table_name) { 'Table1' }
    let(:conditions) { { 'Column2' => 'Column2 Value4' } }

    it { is_expected.to eq(lookup_table_data['Table1'][:rows][1]) }

    context 'when there is no matched record' do
      let(:conditions) { { 'Column2' => 'Column2 Value5' } }

      it { is_expected.to eq({}) }
    end

    context 'when table does not exists' do
      let(:table_name) { 'Table5' }

      it { is_expected.to eq({}) }
    end

    context 'when table id is used' do
      let(:table_name) { 1 }

      it { is_expected.to eq(lookup_table_data['Table1'][:rows][1]) }

      context 'when string as table id' do
        let(:table_name) { '1' }

        it { is_expected.to eq(lookup_table_data['Table1'][:rows][1]) }
      end
    end

    context 'when search in table loaded from yaml' do
      let(:table_name) { 'Table 5' }
      let(:conditions) { { 'Column2' => 'COL-2 Value4' } }

      it { is_expected.to eq('Column1' => 'COL-1 Value3', 'Column2' => 'COL-2 Value4') }
    end

    context 'when search in table loaded from csv' do
      let(:table_name) { 'Table 8' }
      let(:conditions) { { 'Column 4' => 'Value 6' } }

      it { is_expected.to eq('Column 1' => 'Value 4', 'Column 2' => 'Value 5', 'Column 4' => 'Value 6') }

      context 'when search by headers' do
        let(:conditions) { { 'Column 4' => 'Column 4' } }

        it { is_expected.to eq({}) }
      end
    end

    [
      [{ code: 'US' }, 'USA'],
      [{ code: 'IN' }, 'India'],
      [{ code: /IN/ }, 'India'],
      [{ code: /in/i }, 'India'],
      [{ code: /^i.?/i }, 'India'],
      [{ pop: 99_999_999_999 }, 'China'],
      [{ pop: 99_999_999_999.0 }, 'China'],
      [{ pop: (300..100_000_000_000), code: %w[US CH] }, 'China'],
      [{ pop: (250..100_000_000_000) }, 'China'],
      [{ pop: (250..99_999_999_999) }, 'China'],
      [{ pop: (250.0..99_999_999_999.0) }, 'China']
    ].each do |condition, expected_result|
      context "when search by '#{condition}'" do
        let(:table_name) { 'countries' }
        let(:conditions) { condition }

        it { expect(lookup['name']).to eq(expected_result) }
      end
    end

    private

    def lookup_table_data
      @lookup_table_data ||= {
        'Table1' => {
          id: '1',
          rows: [
            {
              'Column1' => 'Column1 Value1',
              'Column2' => 'Column2 Value2'
            },
            {
              'Column1' => 'Column1 Value3',
              'Column2' => 'Column2 Value4'
            }
          ]
        },
        'Table2' => {
          id: '2',
          rows: [
            {
              'Column3' => 'Column3 Value1',
              'Column4' => 'Column4 Value2'
            },
            {
              'Column3' => 'Column3 Value3',
              'Column4' => 'Column4 Value4'
            }
          ]
        }
      }
    end
  end
end
