# typed: false
# frozen_string_literal: true

RSpec.describe 'poll_trigger', :vcr do
  let(:connector) do
    Workato::Connector::Sdk::Connector.from_file('./spec/examples/poll_trigger/connector.rb')
  end
  let(:settings) do
    { user: 'user', password: 'password' }
  end

  describe 'poll_page' do
    it 'polls data and stops after first page' do
      output = connector.triggers.test_trigger.poll_page(settings)

      expect(output).to eq({
        events: [{ 'id' => 2, 'title' => 'Post #2' }, { 'id' => 1, 'title' => 'Post #1' }], # newer events comes first
        next_poll: 2,
        can_poll_more: true
      }.with_indifferent_access)
    end

    context 'when poll with closure from prev poll' do
      it 'polls since cursor position' do
        closure = 2

        output = connector.triggers.test_trigger.poll_page(settings, {}, closure)

        expect(output).to eq({
          events: [{ 'id' => 4, 'title' => 'Post #4' }, { 'id' => 3, 'title' => 'Post #3' }],
          next_poll: 4,
          can_poll_more: true
        }.with_indifferent_access)
      end
    end
  end

  describe 'poll' do
    it 'polls all events at once' do
      output = connector.triggers.test_trigger.poll(settings)

      expect(output).to eq({
        events: [
          { 'id' => 4, 'title' => 'Post #4' },
          { 'id' => 3, 'title' => 'Post #3' },
          { 'id' => 2, 'title' => 'Post #2' },
          { 'id' => 1, 'title' => 'Post #1' }
        ],
        next_poll: 4,
        can_poll_more: false
      }.with_indifferent_access)
    end

    context 'when no new events' do
      it 'does not change cursor' do
        output = connector.triggers.test_trigger.poll(settings, {}, 4)

        expect(output).to eq({
          events: [],
          next_poll: 4,
          can_poll_more: false
        }.with_indifferent_access)
      end
    end
  end
end
