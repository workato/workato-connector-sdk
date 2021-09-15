# frozen_string_literal: true

RSpec.describe 'reusable methods', :vcr do
  let(:settings) { { user: 'user', password: 'password' } }
  let(:connector) do
    Workato::Connector::Sdk::Connector.from_file('./spec/examples/reusable_methods/connector.rb', settings)
  end

  it 'uses defined methods' do
    output = connector.actions.test_action.execute(settings, { foo: 1, bar: 2 })

    expect(output).to include('foo' => '1', 'bar' => '2')
  end

  describe 'test_method' do
    it 'executes request with settings' do
      output = connector.methods.test_method({ foo: 1, bar: 2 })

      expect(output).to include('foo' => '1', 'bar' => '2')
    end
  end
end
