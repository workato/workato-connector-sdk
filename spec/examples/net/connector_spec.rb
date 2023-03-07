# typed: false
# frozen_string_literal: true

RSpec.describe 'net', :vcr do
  let(:connector) { Workato::Connector::Sdk::Connector.from_file('./spec/examples/net/connector.rb') }

  describe 'lookup_a_info' do
    subject(:action) { connector.actions.lookup_a_info.execute }

    let(:expected_output) do
      {
        'output' => [
          { 'address' => '127.0.0.1' }
        ]
      }
    end

    before do
      allow_any_instance_of(Resolv::DNS).to receive(:getresources).and_return(
        [instance_double(Resolv::DNS::Resource::IN::A, { 'address' => '127.0.0.1' })]
      )
    end

    it { is_expected.to include(expected_output) }
  end

  describe 'lookup_srv_info' do
    subject(:action) { connector.actions.lookup_srv_info.execute }

    let(:expected_output) do
      {
        'output' => [
          { 'port' => 10, 'priority' => 10, 'target' => 'ldap.google.com', 'weight' => 10 }
        ]
      }
    end

    before do
      allow_any_instance_of(Resolv::DNS).to receive(:getresources).and_return([instance_double(
        Resolv::DNS::Resource::IN::SRV,
        { 'port' => 10, 'priority' => 10, 'target' => 'ldap.google.com', 'weight' => 10 }
      )])
    end

    it { is_expected.to include(expected_output) }
  end
end
