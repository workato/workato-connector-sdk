# typed: false
# frozen_string_literal: true

module Workato::Extension
  RSpec.describe Currency do
    describe 'country lookup' do
      ['US', 'USA', '840', 'United States', 'United States of America'].each do |cname|
        it "lookups successfully by \"#{cname}\" using all helpers" do
          expect(cname.to_country_alpha2).to eq('US')
          expect(cname.to_country_alpha3).to eq('USA')
          expect(cname.to_country_number).to eq('840')
          expect(cname.to_country_name).to eq('United States')
        end
      end
      it 'does not lookup successfully by "xxxxxx" using all helpers' do
        expect('xxxxxx'.to_country_alpha2).to be_nil
        expect('xxxxxx'.to_country_alpha3).to be_nil
        expect('xxxxxx'.to_country_number).to be_nil
        expect('xxxxxx'.to_country_name).to be_nil
      end
    end

    describe 'state lookup' do
      %w[California CA caliFORNIA].each do |state_name|
        it "lookups successfully by \"#{state_name}\" using all helpers" do
          expect(state_name.to_state_code).to eq('CA')
          expect(state_name.to_state_name).to eq('CALIFORNIA')
        end
      end

      %w[KA Karnataka KarnaTAKa].each do |state_name|
        it "lookups successfully by \"#{state_name}\" using all helpers with country name" do
          expect(state_name.to_state_code('IN')).to eq('KA')
          expect(state_name.to_state_name('IN')).to eq('KARNATAKA')
        end
      end

      it 'does not lookup successfully by "xxxxxx" using all helpers' do
        expect('xxxxxx'.to_state_code).to be_nil
        expect('xxxxxx'.to_state_name).to be_nil
      end

      it 'does not lookup successfully by "xxxxxx" using all helpers with country name' do
        expect('xxxxxx'.to_state_code('IN')).to be_nil
        expect('xxxxxx'.to_state_name('IN')).to be_nil
      end
    end

    describe 'currency lookup' do
      ['US', 'USA', '840', 'United States', 'United States of America'].each do |cname|
        it "lookups successfully by \"#{cname}\" using all helpers" do
          expect(cname.to_currency_symbol).to eq('$')
          expect(cname.to_currency_code).to eq('USD')
          expect(cname.to_currency_name).to eq('Dollars')
        end
      end

      it 'does not lookup successfully by "xxxxxx" using all helpers' do
        expect('xxxxxx'.to_currency_symbol).to be_nil
        expect('xxxxxx'.to_currency_code).to be_nil
        expect('xxxxxx'.to_currency_name).to be_nil
      end
    end
  end
end
