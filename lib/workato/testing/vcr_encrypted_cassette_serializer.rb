# frozen_string_literal: true

module Workato
  module Testing
    class VCREncryptedCassetteSerializer < ActiveSupport::EncryptedFile
      def initialize
        super(
          content_path: '',
          key_path: Workato::Connector::Sdk::DEFAULT_MASTER_KEY_PATH,
          env_key: Workato::Connector::Sdk::DEFAULT_MASTER_KEY_ENV,
          raise_if_missing_key: true
        )
      end

      def file_extension
        'enc'
      end

      def serialize(hash)
        ::Dir::Tmpname.create('vcr_cassette') do |tmp_path|
          @content_path = Pathname.new(tmp_path)
        end
        write(YAML.dump(hash))
        File.binread(content_path)
      ensure
        File.unlink(content_path) if content_path.exist?
      end

      def deserialize(string)
        ::Dir::Tmpname.create('vcr_cassette') do |tmp_path|
          @content_path = Pathname.new(tmp_path)
        end
        File.write(@content_path, string)
        ::YAML.safe_load(read).presence || {}
      end
    end
  end
end
