# typed: false
# frozen_string_literal: true

module Workato::Extension
  RSpec.describe Time do
    describe '#yweek' do
      [
        DateTime.parse('15/1/2015'),
        DateTime.parse('15/1/2015').to_time,
        DateTime.parse('15/1/2015').to_date
      ].each do |value|
        it "returns correct value for #{value.class} value" do
          expect(value.yweek).to eq(3)
        end
      end
    end

    describe '#to_s' do
      let(:time) { ::Time.new(2025, 11, 18, 12, 30, 45) }

      it 'returns the default string representation when no format is provided' do
        expect(time.to_s).to match(/2025-11-18 12:30:45/)
      end

      it 'uses provided format' do
        expect(time.to_s(:db)).to eq('2025-11-18 12:30:45')
      end

      it 'calls the proc with the time' do
        expect(time.to_s(:long_ordinal)).to eq('November 18th, 2025 12:30')
      end

      it 'returns the default string representation when unsupported format is provided' do
        expect(time.to_s(:unsupported_format)).to match(/2025-11-18 12:30:45/)
      end

      context 'with zone info' do
        let(:time) { ActiveSupport::TimeZone['Eastern Time (US & Canada)'].local(2025, 11, 18, 12, 30, 45) }

        it 'returns the default string representation when no format is provided' do
          expect(time.to_s).to match(/2025-11-18 12:30:45 -0500/)
        end

        it 'uses provided format' do
          expect(time.to_s(:db)).to eq('2025-11-18 17:30:45')
        end

        it 'calls the proc with the time' do
          expect(time.to_s(:long_ordinal)).to eq('November 18th, 2025 12:30')
        end

        it 'returns the default string representation when unsupported format is provided' do
          expect(time.to_s(:unsupported_format)).to match(/2025-11-18 12:30:45 -0500/)
        end
      end
    end
  end
end
