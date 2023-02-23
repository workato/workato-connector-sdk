# typed: false
# frozen_string_literal: true

module Workato::Extension
  RSpec.describe Object do
    describe '#is_true?' do
      describe 'for string' do
        %w[true TRUE t T yes YES y Y 1].each do |value|
          it "'#{value}' returns true" do
            expect(value.is_true?).to be(true)
          end
        end

        %w[false FALSE f F no NO n N 0].each do |value|
          it "'#{value}' returns false" do
            expect(value.is_true?).to be(false)
          end
        end

        %w[falsee afalse afalsee ff ono noo onoo nn 00 ttrue truet truet tt yyes yesy yyesy yy 11 23 -20
           foo].each do |value|
          it "'#{value}' raises exception" do
            expect { value.is_true? }.to raise_error(include("Can't convert"))
          end
        end

        ['', '   '].each do |value|
          it 'empty string raises exception' do
            expect { value.is_true? }.to raise_error(include("Can't convert"))
          end
        end
      end

      describe 'for integer' do
        it "'1' returns true" do
          expect(1.is_true?).to be(true)
        end

        it "'0' returns false" do
          expect(0.is_true?).to be(false)
        end

        [-20, -10, 2, 15].each do |value|
          it "'#{value}' raises exception" do
            expect { value.is_true? }.to raise_error(include("Can't convert"))
          end
        end
      end

      describe 'for boolean' do
        it "'true' returns true" do
          expect(true.is_true?).to be(true)
        end

        it "'false' returns false" do
          expect(false.is_true?).to be(false)
        end
      end

      describe 'for nil' do
        it 'nil returns false' do
          expect(nil.is_true?).to be(false)
        end
      end

      describe 'for non integer, string and boolean types' do
        [-50.23, 12.0, ::Time.zone.now, ::Object.new].each do |value|
          it "'#{value}' returns true" do
            expect { value.is_true? }.to raise_error(include("Can't convert"))
          end
        end
      end
    end

    describe '#is_false?' do
      describe 'for string' do
        %w[true TRUE t T yes YES y Y 1].each do |value|
          it "'#{value}' returns false" do
            expect(value.is_not_true?(null_not_true: false)).to be(false)
          end
        end

        %w[false FALSE f F no NO n N 0].each do |value|
          it "'#{value}' returns true" do
            expect(value.is_not_true?(null_not_true: false)).to be(true)
          end
        end

        %w[falsee afalse afalsee ff ono noo onoo nn 00 ttrue truet truet tt yyes yesy yyesy yy 11 23 -20
           foo].each do |value|
          it "'#{value}' raises exception" do
            expect { value.is_not_true?(null_not_true: false) }.to raise_error(include("Can't convert"))
          end
        end

        ['', '   '].each do |value|
          it 'empty string raises exception' do
            expect { value.is_not_true?(null_not_true: false) }.to raise_error(include("Can't convert"))
          end
        end
      end

      describe 'for integer' do
        it "'1' returns false" do
          expect(1.is_not_true?(null_not_true: false)).to be(false)
        end

        it "'0' returns true" do
          expect(0.is_not_true?(null_not_true: false)).to be(true)
        end

        [-20, -10, 2, 15].each do |value|
          it "'#{value}' raises exception" do
            expect { value.is_not_true?(null_not_true: false) }.to raise_error(include("Can't convert"))
          end
        end
      end

      describe 'for boolean' do
        it "'true' returns false" do
          expect(true.is_not_true?(null_not_true: false)).to be(false)
        end

        it "'false' returns true" do
          expect(false.is_not_true?(null_not_true: false)).to be(true)
        end
      end

      describe 'for nil' do
        it 'nil returns false' do
          expect(nil.is_not_true?(null_not_true: false)).to be(false)
        end

        it 'nil returns true' do
          expect(nil.is_not_true?(null_not_true: true)).to be(true)
        end
      end

      describe 'for non integer, string and boolean types' do
        [-50.23, 12.0, ::Time.zone.now, ::Object.new].each do |value|
          it "'#{value}' returns false" do
            expect { value.is_not_true?(null_not_true: false) }.to raise_error(include("Can't convert"))
          end
        end
      end
    end

    describe '#is_not_true?' do
      describe 'for string' do
        %w[false FALSE f F no NO n N 0].each do |value|
          it "'#{value}' returns true" do
            expect(value.is_not_true?).to be(true)
          end
        end

        %w[true TRUE t T yes YES y Y 1].each do |value|
          it "'#{value}' returns false" do
            expect(value.is_not_true?).to be(false)
          end
        end

        %w[falsee afalse afalsee ff ono noo onoo nn 00 ttrue truet truet tt yyes yesy yyesy yy 11 23 -20
           foo].each do |value|
          it "'#{value}' raises exception" do
            expect { value.is_not_true? }.to raise_error(include("Can't convert"))
          end
        end

        ['', '   '].each do |value|
          it 'empty string raises exception' do
            expect { value.is_true? }.to raise_error(include("Can't convert"))
          end
        end
      end

      describe 'for integer' do
        it "'1' returns false" do
          expect(1.is_not_true?).to be(false)
        end

        it "'0' returns true" do
          expect(0.is_not_true?).to be(true)
        end

        [-20, -10, 2, 15].each do |value|
          it "'#{value}' raises exception" do
            expect { value.is_not_true? }.to raise_error(include("Can't convert"))
          end
        end
      end

      describe 'for boolean' do
        it "'true' returns false" do
          expect(true.is_not_true?).to be(false)
        end

        it "'false' returns true" do
          expect(false.is_not_true?).to be(true)
        end
      end

      describe 'for nil' do
        it 'nil returns true' do
          expect(nil.is_not_true?).to be(true)
        end
      end

      describe 'for non integer, string and boolean types' do
        [-50.23, 12.0, ::Time.zone.now, ::Object.new].each do |value|
          it "'#{value}' returns true" do
            expect { value.is_not_true? }.to raise_error(include("Can't convert"))
          end
        end
      end
    end
  end
end
