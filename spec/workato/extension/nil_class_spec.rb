# typed: false
# frozen_string_literal: true

module Workato::Extension
  RSpec.describe NilClass do
    describe '#is_int?' do
      it { expect(nil).not_to be_is_int }
    end

    describe '#is_number?' do
      it { expect(nil).not_to be_is_number }
    end
  end
end
