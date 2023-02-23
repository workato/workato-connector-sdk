# typed: false
# frozen_string_literal: true

RSpec.describe 'csv', :vcr do
  let(:connector) { Workato::Connector::Sdk::Connector.from_file('./spec/examples/csv/connector.rb') }

  describe 'csv_generate' do
    subject(:action) { connector.actions.csv_generate.execute }

    let(:expected_output) do
      {
        'csv0' => "blue,1\nwhite,2\n",
        'csv1' => "blue;1\nwhite;2\n",
        'csv2' => "color;count\nblue;1\nwhite;2\n",
        'csv3' => "color;amount\nblue;1\nwhite;2\n"
      }
    end

    it { is_expected.to include(expected_output) }
  end

  describe 'csv_parse' do
    subject(:action) { connector.actions.csv_parse.execute }

    let(:expected_output) do
      {
        'csv1' => [{ 'color' => 'blue', 'count' => '1' }, { 'color' => 'white', 'count' => '2' }],
        'csv2' => [{ 'color' => 'blue', 'count' => '1' }, { 'color' => 'white', 'count' => '2' }],
        'csv3' => [{ 'color' => 'blue', 'count' => '1' }, { 'color' => 'white', 'count' => '2' }]
      }
    end

    it { is_expected.to include(expected_output) }
  end
end
