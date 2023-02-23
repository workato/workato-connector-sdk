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
  end
end
