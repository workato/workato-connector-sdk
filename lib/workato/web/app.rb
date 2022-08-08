# typed: true
# frozen_string_literal: true

module Workato
  module Web
    class App
      CODE_PATH = '/code'
      CALLBACK_PATH = '/oauth/callback'

      def call(env)
        req = Rack::Request.new(env)
        case req.path_info
        when /#{CODE_PATH}/
          [200, { 'Content-Type' => 'text/plain' }, [@code.to_s]]
        when /#{CALLBACK_PATH}/
          @code = req.params['code']
          [200, { 'Content-Type' => 'text/plain' }, ['We stored response code. Now you can close the browser window']]
        else
          [404, { 'Content-Type' => 'text/plain' }, ['404: Not Found']]
        end
      end
    end
  end
end
