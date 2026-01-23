# typed: false
# frozen_string_literal: true

module Workato::Extension
  RSpec.describe Date do
    let(:date) { ::Date.new(2025, 11, 18) }

    describe '#yweek' do
      it 'returns the correct week number' do
        expect(date.yweek).to eq(47)
      end
    end

    describe '#to_s' do
      it 'returns the default string representation when no format is provided' do
        expect(date.to_s).to eq('2025-11-18')
      end

      it 'uses provided format' do
        expect(date.to_s(:db)).to eq('2025-11-18')
      end

      it 'calls the proc with the datetime' do
        expect(date.to_s(:long_ordinal)).to eq('November 18th, 2025')
      end

      it 'returns the default string representation when unsupported format is provided' do
        expect(date.to_s(:unsupported_format)).to eq('2025-11-18')
      end

      context 'with custom default formatter' do
        around do |example|
          original_default_formatter = ::Date::DATE_FORMATS[:default]
          ::Date::DATE_FORMATS[:default] = default_formatter
          example.run
          ::Date::DATE_FORMATS[:default] = original_default_formatter
        end

        context 'when default formatter is a string' do
          let(:default_formatter) { '%m-%d-%Y' }

          it 'uses the string format for default formatting' do
            expect(date.to_s).to eq('11-18-2025')
          end
        end

        context 'when default formatter is a proc' do
          let(:default_formatter) do
            proc { |d| d.strftime('%d/%m/%Y') }
          end

          it 'uses the proc for default formatting' do
            expect(date.to_s).to eq('18/11/2025')
          end
        end
      end
    end

    context 'when used with DateTime' do
      let(:datetime) { ::DateTime.new(2025, 11, 18, 12, 30, 45) }

      describe '#yweek' do
        it 'returns the correct week number' do
          expect(datetime.yweek).to eq(47)
        end
      end

      describe '#to_s' do
        describe '#yweek' do
          it 'returns the correct week number' do
            expect(datetime.yweek).to eq(47)
          end
        end

        describe '#to_s' do
          it 'returns the default string representation when no format is provided' do
            expect(datetime.to_s).to match(/2025-11-18T12:30:45/)
          end

          it 'uses provided format' do
            expect(datetime.to_s(:db)).to eq('2025-11-18 12:30:45')
          end

          it 'calls the proc with the datetime' do
            expect(datetime.to_s(:long_ordinal)).to eq('November 18th, 2025 12:30')
          end

          it 'returns the default string representation when unsupported format is provided' do
            expect(datetime.to_s(:unsupported_format)).to match(/2025-11-18T12:30:45/)
          end

          context 'with custom default formatter' do
            around do |example|
              original_default_formatter = ::Time::DATE_FORMATS[:default]
              ::Time::DATE_FORMATS[:default] = default_formatter
              example.run
              ::Time::DATE_FORMATS[:default] = original_default_formatter
            end

            context 'when default formatter is a string' do
              let(:default_formatter) { '%m-%d-%Y %H:%M' }

              it 'uses the string format for default formatting' do
                expect(datetime.to_s).to eq('11-18-2025 12:30')
              end
            end

            context 'when default formatter is a proc' do
              let(:default_formatter) do
                proc { |d| d.strftime('%m-%d-%Y %H:%M') }
              end

              it 'uses the proc for default formatting' do
                expect(datetime.to_s).to eq('11-18-2025 12:30')
              end
            end
          end
        end
      end
    end
  end
end
