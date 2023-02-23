# typed: false
# frozen_string_literal: true

module Workato::Connector::Sdk
  RSpec.describe Action do
    subject(:action) { described_class.new(action: action_definition, methods: methods) }

    let(:action_definition) do
      {
        'execute' => lambda do |settings, input, extended_input_schema, extended_output_schema, continue|
          call('join', settings, input, extended_input_schema, extended_output_schema, continue)
        end
      }
    end
    let(:methods) do
      {
        'join' => lambda do |settings, input, extended_input_schema, extended_output_schema, continue|
          {
            settings: settings,
            input: input,
            extended_input_schema: extended_input_schema,
            extended_output_schema: extended_output_schema,
            continue: continue
          }
        end
      }
    end

    let(:settings) do
      { user: 'user', 'password' => 'password' }
    end
    let(:input) do
      { param1: 'value1' }
    end
    let(:extended_input_schema) do
      { field1: '1', 'field2' => 2 }
    end
    let(:extended_output_schema) do
      { field3: '3', 'field4' => 4 }
    end

    it 'executes execute block of the action' do
      output = action.execute(settings, input, [extended_input_schema], [extended_output_schema])
      expect(output).to eq(
        'settings' => settings.with_indifferent_access,
        'input' => input.with_indifferent_access,
        'extended_input_schema' => [extended_input_schema.with_indifferent_access],
        'extended_output_schema' => [extended_output_schema.with_indifferent_access],
        'continue' => {}.with_indifferent_access
      )
    end

    context 'when execute block is missing' do
      let(:action_definition) { {} }

      it { expect { action.execute }.to raise_error(InvalidDefinitionError) }
    end

    context 'when multistep action' do
      let(:action_definition) do
        {
          'execute' => lambda do |settings, input, extended_input_schema, extended_output_schema, continue|
            if continue.blank?
              reinvoke_after(seconds: 5, continue: { completed: true })
              return { completed: false }
            end

            call('join', settings, input, extended_input_schema, extended_output_schema, continue)
          end
        }
      end

      it 'executes execute block multiple times' do
        allow(Kernel).to receive(:sleep)

        output = action.execute(settings, input, [extended_input_schema], [extended_output_schema])
        expect(output).to eq(
          'settings' => settings.with_indifferent_access,
          'input' => input.with_indifferent_access,
          'extended_input_schema' => [extended_input_schema.with_indifferent_access],
          'extended_output_schema' => [extended_output_schema.with_indifferent_access],
          'continue' => { completed: true }.with_indifferent_access
        )
        expect(Kernel).to have_received(:sleep).with(5).once
      end

      it 'can be speed up in tests' do
        allow(Kernel).to receive(:sleep)

        expect { action.execute }.to change { Process.clock_gettime(Process::CLOCK_MONOTONIC) }.by_at_most(4.99)
      end

      it 'can be speed up in CLI' do
        ENV['WAIT_REINVOKE_AFTER'] = '0'

        expect { action.execute }.to change { Process.clock_gettime(Process::CLOCK_MONOTONIC) }.by_at_most(4.99)
      ensure
        ENV.delete('WAIT_REINVOKE_AFTER')
      end

      context 'when infinite reinvokes' do
        let(:action_definition) do
          {
            'execute' => lambda {
              reinvoke_after(seconds: 10, continue: { completed: false })
            }
          }
        end

        it 'executes execute block no more than allowed times' do
          allow(Kernel).to receive(:sleep)

          expect { action.execute }.to raise_error('Max number of reinvokes on SDK Gem reached. Current limit is 5')
          expect(Kernel).to have_received(:sleep).with(10).exactly(5)
        end
      end
    end
  end
end
