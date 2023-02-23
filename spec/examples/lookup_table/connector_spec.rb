# typed: false
# frozen_string_literal: true

RSpec.describe 'lookup_table' do
  before(:all) do
    Workato::Connector::Sdk::LookupTables.from_csv(8, 'CSV Table', 'spec/fixtures/lookup_table.csv')
  end

  let(:connector) do
    Workato::Connector::Sdk::Connector.from_file('./spec/examples/lookup_table/connector.rb')
  end

  it 'searches in lookup table' do
    query = { 'Column 2' => 'Value 5', 'Column 4' => 'Value 6' }
    output = connector.actions.action_with_lookup_table.execute({}, { q: query })

    expect(output).to eq('Column 1' => 'Value 4', 'Column 2' => 'Value 5', 'Column 4' => 'Value 6')
  end
end
