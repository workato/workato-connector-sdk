# typed: false
# frozen_string_literal: true

module Workato::Connector::Sdk
  RSpec.describe Dsl::Call do
    context 'when action calls existing method' do
      let(:action) { Action.new(action: connector[:actions][:join], methods: connector[:methods]) }
      let(:input) { { a: :a, b: :b } }

      subject { action.execute({}, input) }

      it { is_expected.to eq('a, b : a, b') }
    end

    context 'when action calls undefined method' do
      let(:action) { Action.new(action: connector[:actions][:join], methods: {}) }

      subject { action.execute }

      it { expect { subject }.to raise_error(InvalidDefinitionError) }
    end

    private

    def connector
      {
        actions: {
          join: {
            execute: lambda do |_connection, input, _extended_input_schema, _extended_output_schema|
              s1 = call('join', input['a'], input['b'])
              s2 = call(:join, input[:a], input[:b])
              [s1, s2].join(' : ')
            end
          }
        },

        methods: {
          join: lambda do |arg1, arg2|
            [arg1, arg2].join(', ')
          end
        }
      }
    end
  end
end
