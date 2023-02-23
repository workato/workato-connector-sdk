# typed: false
# frozen_string_literal: true

RSpec.describe Workato::Connector::Sdk do
  it 'has a version number' do
    expect(Workato::Connector::Sdk::VERSION).to be_a(String)
  end

  it 'executes action' do
    connector = described_class::Connector.from_file('./spec/fixtures/connectors/hello_world.rb')
    expect(connector.actions.foo.execute).to eq('Hello, World!')
  end

  it 'executes action with request', :vcr do
    connector = described_class::Connector.from_file('./spec/fixtures/connectors/hello_world.rb')
    expect(connector.actions.bar.execute).to eq('10.11.12.13')
  end
end
