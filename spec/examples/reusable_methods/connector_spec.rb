# typed: false
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

  context 'when call method with invalid definition' do
    it 'raises invalid definition error' do
      expect do
        connector.actions.with_unexpected_type_error.execute
      end.to raise_error(Workato::Connector::Sdk::UnexpectedMethodDefinitionError)
    end
  end

  context 'when call unknown method' do
    it 'raises invalid definition error' do
      expect do
        connector.actions.with_undefined_method_error.execute
      end.to raise_error(Workato::Connector::Sdk::UndefinedMethodError)
    end
  end

  describe 'test_method' do
    it 'executes request with settings' do
      output = connector.methods.test_method({ foo: 1, bar: 2 })

      expect(output).to include('foo' => '1', 'bar' => '2')
    end
  end

  describe 'unexpected_type_error' do
    it 'raises invalid definition error' do
      expect do
        connector.methods.unexpected_type_error
      end.to raise_error(Workato::Connector::Sdk::UnexpectedMethodDefinitionError)
    end
  end
end
