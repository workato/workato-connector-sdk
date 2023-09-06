# typed: false
# frozen_string_literal: true

module Workato::Connector::Sdk
  RSpec.describe Dsl::HTTP do
    let(:url) { 'http://example.com' }
    let(:execution_context) { ExecutionContext.new }
    let(:request_mock) do
      request = instance_double(Request)
      allow(request).to receive_messages(
        payload: request,
        params: request,
        response_format_json: request,
        format_json: request
      )
      request
    end

    before do
      allow(Request).to receive(:new).and_return(request_mock)
    end

    shared_examples 'GET' do |method|
      it "returns preconfigured requests with #{method} HTTP verb" do
        build_request

        expect(Request).to have_received(:new).with(
          url,
          method: method,
          action: execution_context,
          connection: execution_context.connection
        ).once
        expect(request_mock).to have_received(:params).with({ foo: :bar }).once
        expect(request_mock).to have_received(:response_format_json).once
      end
    end

    describe '#get' do
      it_behaves_like 'GET', 'GET' do
        subject(:build_request) { execution_context.get(url, foo: :bar) }
      end
    end

    describe '#options' do
      it_behaves_like 'GET', 'OPTIONS' do
        subject(:build_request) { execution_context.options(url, foo: :bar) }
      end
    end

    describe '#head' do
      it_behaves_like 'GET', 'HEAD' do
        subject(:build_request) { execution_context.head(url, foo: :bar) }
      end
    end

    shared_examples 'POST' do |method|
      it "returns preconfigured requests with #{method} HTTP verb" do
        build_request

        expect(Request).to have_received(:new).with(
          url,
          method: method,
          action: execution_context,
          connection: execution_context.connection
        ).once
        expect(request_mock).to have_received(:payload).with({ foo: :bar }).once
        expect(request_mock).to have_received(:format_json).once
      end
    end

    describe '#post' do
      it_behaves_like 'POST', 'POST' do
        subject(:build_request) { execution_context.post(url, foo: :bar) }
      end
    end

    describe '#patch' do
      it_behaves_like 'POST', 'PATCH' do
        subject(:build_request) { execution_context.patch(url, foo: :bar) }
      end
    end

    describe '#put' do
      it_behaves_like 'POST', 'PUT' do
        subject(:build_request) { execution_context.put(url, foo: :bar) }
      end
    end

    describe '#delete' do
      it_behaves_like 'POST', 'DELETE' do
        subject(:build_request) { execution_context.delete(url, foo: :bar) }
      end
    end

    describe '#copy' do
      it_behaves_like 'POST', 'COPY' do
        subject(:build_request) { execution_context.copy(url, foo: :bar) }
      end
    end

    describe '#move' do
      it_behaves_like 'POST', 'MOVE' do
        subject(:build_request) { execution_context.move(url, foo: :bar) }
      end
    end
  end

  class ExecutionContext
    include Dsl::HTTP

    def connection
      @connection ||= Connection.new
    end
  end
end
