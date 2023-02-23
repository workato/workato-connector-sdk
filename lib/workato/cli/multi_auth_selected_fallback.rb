# typed: false
# frozen_string_literal: true

module Workato
  module CLI
    module MultiAuthSelectedFallback
      private

      def multi_auth_selected_fallback(options)
        say('Please select current auth type for multi-auth connector:')
        options = options.keys
        options.each_with_index do |option, idx|
          say "[#{idx + 1}] #{option}"
        end
        say '[q] <exit>'
        say('')

        multi_auth_selected_fallback = loop do
          answer = ask('Your choice:').to_s.downcase
          break if answer == 'q'
          next unless /\d+/ =~ answer && options[answer.to_i - 1]

          break options[answer.to_i - 1]
        end
        return unless multi_auth_selected_fallback

        say('')
        say('Put selected auth type in your settings file to avoid this message in future')

        multi_auth_selected_fallback
      end
    end
  end
end
