# typed: false
# frozen_string_literal: true

module Workato::Extension
  RSpec.describe Numeric do
    describe '#to_s' do
      it 'returns the default string representation when no format is provided' do
        expect(1234.to_s).to eq('1234')
        expect(12.34.to_s).to eq('12.34')
        expect(BigDecimal('12.34567').to_s).to eq('12.34567')
      end

      it 'uses provided format' do
        expect(1234.to_s(:delimited)).to eq('1,234')
        expect(12.34.to_s(:currency)).to eq('$12.34')
        expect(1_234_567_890.to_s(:phone)).to eq('123-456-7890')
        expect(85.to_s(:percentage)).to eq('85.000%')
        expect(1234.to_s(:human)).to eq('1.23 Thousand')
        expect(1_234_567_890.to_s(:human_size)).to eq('1.15 GB')

        expect(12.34.to_s(:rounded)).to eq('12.340')
        expect(BigDecimal('12.34567').to_s(:rounded)).to eq('12.346')
      end

      it 'returns the default string representation when unsupported format is provided' do
        expect(1234.to_s(:unsupported_format)).to eq('1234')
        expect(12.34.to_s(:unsupported_format)).to eq('12.34')
        expect(BigDecimal('12.34567').to_s(:unsupported_format)).to eq('12.34567')
      end
    end
  end
end
