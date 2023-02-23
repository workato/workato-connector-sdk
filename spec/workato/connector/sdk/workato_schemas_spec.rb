# typed: false
# frozen_string_literal: true

module Workato::Connector::Sdk
  RSpec.describe WorkatoSchemas do
    before(:all) do
      described_class.from_json('spec/fixtures/workato_schemas.json')
    end

    it 'allows search schema by id' do
      schema = described_class.find(99)

      expect(schema).not_to be_empty
    end

    context 'when schema does not exists' do
      it 'raises error' do
        expect { described_class.find(100) }.to raise_error(KeyError)
      end
    end
  end
end
