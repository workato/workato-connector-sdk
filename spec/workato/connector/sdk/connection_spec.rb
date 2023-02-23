# typed: false
# frozen_string_literal: true

module Workato::Connector::Sdk
  RSpec.describe Connection do
    let(:connection) { described_class.new(connection: source) }

    describe '#acquire' do
      subject(:output) { connection.authorization.acquire }

      [{}, [{}], [{}, nil], [{}, nil, nil]].each do |acquire_output|
        context "when OAuth2 returns #{acquire_output}" do
          let(:source) do
            {
              authorization: {
                type: 'oauth2',
                acquire: -> { acquire_output }
              }
            }
          end

          it { is_expected.to eq(acquire_output) }
        end
      end
    end
  end
end
