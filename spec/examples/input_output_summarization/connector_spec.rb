# typed: false
# frozen_string_literal: true

RSpec.describe 'input_output_summarization' do
  let(:connector) do
    Workato::Connector::Sdk::Connector.from_file('./spec/examples/input_output_summarization/connector.rb')
  end

  let(:data) do
    {
      'report' => {
        'records' => (0..999).map do |i|
          {
            'item_name' => "Item #{i}"
          }
        end,
        'description' => 'abcdefgh' * 128 * 2,
        'comment' => 'abcdefgh' * 128 * 2
      }
    }
  end

  %i[summarize_input summarize_output].each do |method|
    describe method do
      it 'summarizes input' do
        summarized_data = connector.actions.test_action.public_send(method, data)

        expect(data['report']['records'].length).to eq(1000)
        expect(summarized_data['report']['records'].length).to eq(100)
        expect(summarized_data['report']['records'][-2]).to end_with('...')

        expect(data['report']['description'].length).to eq(2048)
        expect(summarized_data['report']['description'].length).to be < 2048
        expect(summarized_data['report']['description']).to end_with('...')

        expect(data['report']['comment']).to eq(summarized_data['report']['comment'])
      end
    end
  end
end
