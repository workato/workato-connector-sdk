# typed: false
# frozen_string_literal: true

RSpec.describe 'random', :vcr do
  let(:connector) { Workato::Connector::Sdk::Connector.from_file('./spec/examples/random/connector.rb') }

  describe 'test' do
    it { expect(connector.test).to be_between(0, 1000) }
  end

  describe 'actions' do
    describe 'get_random_integer' do
      describe 'execute' do
        subject(:random_integer) { connector.actions.get_random_integer.execute({}, input) }

        let(:min) { 10 }
        let(:max) { 10_000 }
        let(:input) { { 'min' => min, 'max' => max } }

        shared_examples 'successful' do
          let(:min_value) { min }
          let(:max_value) { max }

          it 'returns positive integer' do
            expect(random_integer['value']).to be_a(Integer)
            expect(random_integer['value']).to be_positive
            expect(random_integer['value']).to be_between(min_value, max_value)
          end
        end

        it_behaves_like 'successful'

        context 'when min is blank' do
          let(:min) { nil }

          it_behaves_like 'successful' do
            let(:min_value) { 1 }
          end
        end

        context 'when max is blank' do
          let(:max) { nil }

          it_behaves_like 'successful' do
            let(:max_value) { 9_007_199_254_740_991 }
          end

          context 'when min is huge' do
            let(:min) { 9_007_199_254_740_991 + 1 }

            it { expect { random_integer }.to raise_error('Max must be greater or equal to min') }
          end
        end

        context 'when min is not a number' do
          let(:min) { 'not a number' }

          it { expect { random_integer }.to raise_error('Min must be a positive integer, got not a number') }
        end

        context 'when max is not a number' do
          let(:max) { 'not a number' }

          it { expect { random_integer }.to raise_error('Max must be a positive integer, got not a number') }
        end

        context 'when min > max' do
          let(:min) { 10 }
          let(:max) { 1 }

          it { expect { random_integer }.to raise_error('Max must be greater or equal to min') }
        end
      end

      describe 'sample_output' do
        it { expect(connector.actions.get_random_integer.sample_output).to eq('value' => 42) }
      end

      describe 'input_fields' do
        it 'accepts min param' do
          input_fields = connector.actions.get_random_integer.input_fields

          expect(input_fields).to include(hash_including(name: 'min', type: 'integer'))
        end

        it 'accepts max param' do
          input_fields = connector.actions.get_random_integer.input_fields

          expect(input_fields).to include(hash_including(name: 'max', type: 'integer'))
        end
      end

      describe 'output_fields' do
        it 'returns value' do
          input_fields = connector.actions.get_random_integer.output_fields

          expect(input_fields).to include(hash_including(name: 'value', type: 'integer'))
        end
      end
    end
  end

  describe 'methods' do
    describe 'positive_integer?' do
      [1, '1', '1000'].each do |n|
        it { expect(connector.methods.positive_integer?(n)).to be_truthy } # rubocop:disable RSpec/PredicateMatcher
      end

      [-1, '-1', '0', 'abc', '', nil].each do |n|
        it { expect(connector.methods.positive_integer?(n)).to be_falsey } # rubocop:disable RSpec/PredicateMatcher
      end
    end
  end
end
