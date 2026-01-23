# typed: false
# frozen_string_literal: true

module Workato::Extension
  RSpec.describe Array do
    describe '#sum' do
      context 'with numeric elements' do
        it 'sums numeric values without init' do
          expect([1, 2, 3].sum).to eq(6)
        end

        it 'sums numeric values with init' do
          expect([1, 2, 3].sum(10)).to eq(16)
        end

        it 'sums numeric values with block' do
          expect([1, 2, 3].sum { |n| n * 2 }).to eq(12)
        end

        it 'sums numeric values with init and block' do
          expect([1, 2, 3].sum(5) { |n| n * 2 }).to eq(17)
        end
      end

      context 'with string elements' do
        it 'concatenates strings without init' do
          expect(%w[a b c].sum).to eq('abc')
        end

        it 'concatenates strings with init' do
          expect(%w[a b c].sum('start:')).to eq('start:abc')
        end

        it 'concatenates strings with block' do
          expect(%w[a b c].sum { |s| "#{s}-" }).to eq('a-b-c-')
        end

        it 'concatenates strings with init and block' do
          expect(%w[a b c].sum('start:') { |s| "#{s}-" }).to eq('start:a-b-c-')
        end
      end
    end

    describe '#to_s' do
      context 'without format' do
        it 'returns the default string representation' do
          expect([1, 2, 3].to_s).to eq('[1, 2, 3]')
          expect([1, 2, 3].to_s(nil)).to eq('[1, 2, 3]')
        end
      end

      context 'with :db format' do
        it 'returns "null" for empty array' do
          expect([].to_s(:db)).to eq('null')
        end

        it 'returns comma-separated ids for an array of objects with id' do
          struct = Struct.new(:id, :name)
          records = [
            struct.new(1, 'Record1'),
            struct.new(2, 'Record2'),
            struct.new(3, 'Record3')
          ]

          expect(records.to_s(:db)).to eq('1,2,3')
        end

        it 'raises NoMethodError for an array of objects without id' do
          object = ::Object.new
          records = [object, object, object]

          expect { records.to_s(:db) }.to raise_error(NoMethodError, /undefined method `id'/)
        end
      end

      context 'with unsupported format' do
        subject { [1, 2, 3].to_s(:xml) }

        it 'returns the default string representation' do
          expect(subject).to eq('[1, 2, 3]')
        end
      end

      context 'with string format parameter' do
        subject { [1, 2, 3].to_s('db') }

        it 'returns the default string representation (format must be symbol)' do
          expect(subject).to eq('[1, 2, 3]')
        end
      end
    end
  end
end
