# typed: false
# frozen_string_literal: true

module Workato::Connector::Sdk
  RSpec.describe Dsl::NetPackage do
    subject(:package) { described_class.new }

    describe '.lookup' do
      subject(:result) { package.lookup(name, record) }

      let(:name) { 'www.google.com' }
      let(:record) { 'A' }

      context 'when A record' do
        let(:record) { 'A' }

        before do
          allow_any_instance_of(Resolv::DNS).to receive(:getresources).and_return(
            [instance_double(Resolv::DNS::Resource::IN::A, { 'address' => '127.0.0.1' })]
          )
        end

        it { is_expected.to contain_exactly({ address: '127.0.0.1' }) }
      end

      context 'when SRV record' do
        let(:record) { 'SRV' }

        before do
          allow_any_instance_of(Resolv::DNS).to receive(:getresources).and_return([instance_double(
            Resolv::DNS::Resource::IN::SRV,
            { 'port' => 10, 'priority' => 10, 'target' => 'ldap.google.com', 'weight' => 10 }
          )])
        end

        it 'returns expected data' do
          expect(result).to contain_exactly({ port: 10, priority: 10, target: 'ldap.google.com', weight: 10 })
        end
      end

      context 'when resolv gem raises resolv error' do
        before do
          allow_any_instance_of(Resolv::DNS).to receive(:getresources).and_raise(
            Resolv::ResolvError, 'Cannot resolve host name'
          )
        end

        it 'fails with error' do
          expect { result }.to raise_error(NetLookupError, 'Cannot resolve host name')
        end
      end

      context 'when resolv gem raises resolv timeout' do
        before do
          allow_any_instance_of(Resolv::DNS).to receive(:getresources).and_raise(
            Resolv::ResolvTimeout, 'Taking too long to resolve host name'
          )
        end

        it 'fails with error' do
          expect { result }.to raise_error(NetLookupError, 'Taking too long to resolve host name')
        end
      end

      context 'when invalid record type' do
        let(:record) { 'unknown' }

        it 'fails with error' do
          expect { result }.to raise_error(ArgumentError, 'Record type not supported, Supported types: "A", "SRV"')
        end
      end
    end

    context 'when undefined method' do
      it 'raises user-friendly error' do
        expect { package.foo }.to raise_error("Undefined method 'foo' for \"workato.net\" namespace")
      end
    end
  end
end
