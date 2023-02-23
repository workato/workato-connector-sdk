# typed: false
# frozen_string_literal: true

module Workato::Connector::Sdk
  RSpec.describe AccountProperties do
    before(:all) do
      described_class.load_data(account_properties_data)
      described_class.from_yaml('spec/fixtures/account_properties.yaml')
      described_class.from_encrypted_yaml('spec/fixtures/account_properties.yaml.enc', 'spec/fixtures/master.key')
      described_class.from_csv('spec/fixtures/account_properties.csv')
    end

    subject(:get) { described_class.get(property) }

    let(:property) { 'key1' }

    it { is_expected.to eq(account_properties_data[:key1]) }

    context 'when value is not a string' do
      let(:property) { 'key2' }

      it { is_expected.to eq(account_properties_data['key2'].to_s) }
    end

    context 'when property does not exists' do
      let(:property) { 'key10' }

      it { is_expected.to be_nil }
    end

    context 'when symbol is used for key' do
      let(:property) { :key2 }

      it { is_expected.to eq(account_properties_data['key2'].to_s) }
    end

    context 'when loaded from yaml' do
      let(:property) { :key4 }

      it { is_expected.to eq('value4') }
    end

    context 'when loaded from csv' do
      let(:property) { :key6 }

      it { is_expected.to eq('value6') }
    end

    context 'when ERB is used in value' do
      let(:property) { :erb_key1 }

      it { is_expected.to eq('erb_value_1') }
    end

    context 'when loaded from encrypted yaml' do
      let(:property) { :key7 }

      it { is_expected.to eq('secret7') }
    end

    private

    def account_properties_data
      @account_properties_data ||= {
        key1: 'value1',
        'key2' => :value2
      }
    end
  end
end
