# typed: false
# frozen_string_literal: true

module Workato::Extension
  RSpec.describe CaseSensitiveHeaders do
    let(:request) { Net::HTTP::Get.new('http://example.com', headers.merge(case_sensitive_headers)) }

    let(:headers) do
      {
        'x-hEaDer-1' => 'x-hEaDer-1',
        'x_hEaDer-2' => 'x_hEaDer-2'
      }
    end
    let(:case_sensitive_headers) do
      {
        'x-hEaDer-3' => 'x-hEaDer-3',
        'x_hEaDer-4' => 'x-hEaDer-4'
      }
    end

    it 'keeps headers case' do
      request.case_sensitive_headers = case_sensitive_headers
      expect(request.each_capitalized.to_a).to include(
        %w[x-hEaDer-3 x-hEaDer-3],
        %w[x_hEaDer-4 x-hEaDer-4]
      )
    end

    context 'without case_sensitive_headers' do
      it 'downcase headers' do
        expect(request.each_capitalized.to_a).to include(
          %w[X-Header-3 x-hEaDer-3],
          %w[X_header-4 x-hEaDer-4]
        )
      end
    end
  end
end
