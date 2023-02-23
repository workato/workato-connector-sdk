# typed: false
# frozen_string_literal: true

RSpec.describe 'pick_lists', :vcr do
  let(:connector) { Workato::Connector::Sdk::Connector.from_file('./spec/examples/pick_lists/connector.rb') }

  let(:settings) { { user: 'user', password: 'password' } }

  context 'when static' do
    it 'returns result' do
      pick_list = connector.pick_lists.static

      expect(pick_list).to be_a(Array)
      expect(pick_list).not_to be_empty
    end

    context 'when defined with connection param' do
      it 'returns result' do
        pick_list = connector.pick_lists.with_connection

        expect(pick_list).to be_a(Array)
        expect(pick_list).not_to be_empty
      end
    end
  end

  context 'when dependent & static' do
    it 'returns result' do
      pick_list = connector.pick_lists.dependent_static(settings, index: 1)

      expect(pick_list).to eq(%w[Webinar webinar])
    end

    context 'without required param' do
      it 'raises error' do
        expect { connector.pick_lists.dependent_static(settings) }.to raise_error(ArgumentError)
      end
    end

    context 'without optional param' do
      it 'returns result' do
        pick_list = connector.pick_lists.with_default_param(settings)

        expect(pick_list).to eq(%w[Meeting meeting])
      end
    end
  end

  context 'when dependent & dynamic' do
    it 'returns result' do
      pick_list = connector.pick_lists.dependent_dynamic(settings, index: 0)

      expect(pick_list).to eq(%w[Meeting meeting])
    end
  end

  context 'when tree list' do
    context 'when fetch root element' do
      it 'returns result' do
        pick_list = connector.pick_lists.tree(settings, index: 1)

        expect(pick_list).to eq([['Root', 'root', 0, true]])
      end
    end

    context 'when fetch child elements' do
      it 'returns result' do
        pick_list = connector.pick_lists.tree(settings, index: 1, __parent_id: 0)

        expect(pick_list).to eq([['Webinar', 'webinar', 1, false]])
      end
    end
  end
end
