# typed: true
# frozen_string_literal: true

module Workato
  module CLI
    module Generators
      class MasterKeyGenerator < Thor::Group
        include Thor::Actions

        no_commands do
          def call(key_path = Workato::Connector::Sdk::DEFAULT_MASTER_KEY_PATH)
            create_key_file(key_path)
            ignore_key_file(key_path)
          end
        end

        def create_key_file(key_path = Workato::Connector::Sdk::DEFAULT_MASTER_KEY_PATH)
          raise "#{key_path} already exists" if File.exist?(key_path)

          key = ActiveSupport::EncryptedFile.generate_key

          say "Adding #{key_path} to store the encryption key: #{key}"
          say ''
          say 'Save this in a password manager your team can access.'
          say "Don't store the file in a public place, make sure you're sharing it privately."
          say ''
          say 'If you lose the key, no one, including you, can access anything encrypted with it.'

          say ''

          File.open(key_path, 'w') do |f|
            f.write(key)
            f.chmod 0o600
          end

          say ''
        end

        def ignore_key_file(key_path = Workato::Connector::Sdk::DEFAULT_MASTER_KEY_PATH)
          ignore = [' ', "/#{key_path}", ' '].join("\n")
          if File.exist?('.gitignore')
            unless File.read('.gitignore').include?(ignore)
              say "Ignoring #{key_path} so it won't end up in Git history:"
              say ''
              append_to_file '.gitignore', ignore
              say ''
            end
          else
            say "IMPORTANT: Don't commit #{key_path}. Add this to your ignore file:"
            say ignore, :on_green
            say ''
          end
        end
      end
    end
  end
end
