# typed: false
# frozen_string_literal: true

module Workato::Extension
  RSpec.describe Hash do
    describe '#encode_www_form' do
      subject { { string: 'foo', number: 123, null: nil, array: [1, 2, 3] }.encode_www_form }

      it { is_expected.to eq('string=foo&number=123&null&array=1&array=2&array=3') }
    end
  end
end
