# typed: false
# frozen_string_literal: true

module Workato::Extension
  RSpec.describe Range do
    describe '#to_s' do
      it 'returns the default string representation when no format is provided' do
        expect((1..10).to_s).to eq('1..10')
      end

      it 'uses provided format' do
        expect((1..10).to_s(:db)).to eq("BETWEEN '1' AND '10'")
      end

      it 'returns the default string representation when unsupported format is provided' do
        expect((1..10).to_s(:unsupported_format)).to eq('1..10')
      end
    end
  end
end
