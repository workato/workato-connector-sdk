# typed: false
# frozen_string_literal: true

module Workato::Connector::Sdk
  RSpec.describe Settings do
    describe '.from_file' do
      it 'loads settings as hash' do
        settings = described_class.from_file('spec/fixtures/settings.yaml')

        expect(settings).to eq(
          'My Valid Connection' => {
            'user' => 'user',
            'password' => 'password'
          },
          'My Invalid Connection' => {
            'user' => 'user',
            'password' => 'invalid'
          }
        )
      end

      context 'when file has multiple connections' do
        it 'fetches connection by name' do
          settings = described_class.from_file('spec/fixtures/settings.yaml', 'My Invalid Connection')

          expect(settings).to eq(
            'user' => 'user',
            'password' => 'invalid'
          )
        end
      end
    end

    describe '.from_encrypted_file' do
      it 'loads settings as hash' do
        settings = described_class.from_encrypted_file('spec/fixtures/settings.yaml.enc', 'spec/fixtures/master.key')
        expect(settings).to eq(
          'My Valid Connection' => {
            'user' => 'user',
            'password' => 'password'
          },
          'My Invalid Connection' => {
            'user' => 'user',
            'password' => 'invalid'
          }
        )
      end

      context 'without key file' do
        it 'raises exception' do
          expect { described_class.from_encrypted_file('spec/fixtures/settings.yaml.enc') }
            .to raise_error(ActiveSupport::EncryptedFile::MissingKeyError)
        end

        context 'when default key file exists' do
          it 'loads settings as hash' do
            stub_const('Workato::Connector::Sdk::DEFAULT_MASTER_KEY_PATH', 'spec/fixtures/master.key')

            settings = described_class.from_encrypted_file('spec/fixtures/settings.yaml.enc')

            expect(settings).not_to be_empty
          end
        end

        context 'when ENV has DEFAULT_MASTER_KEY_ENV variable set' do
          it 'loads settings as hash' do
            allow(ENV).to receive(:[]).with(DEFAULT_MASTER_KEY_ENV).and_return('d113939d9dd3b4af7ff58b6c3013b348')

            settings = described_class.from_encrypted_file('spec/fixtures/settings.yaml.enc')

            expect(settings).not_to be_empty
          end
        end
      end

      context 'when file has multiple connections' do
        it 'fetches connection by name' do
          settings = described_class.from_encrypted_file(
            'spec/fixtures/settings.yaml.enc',
            'spec/fixtures/master.key',
            'My Invalid Connection'
          )

          expect(settings).to eq('user' => 'user', 'password' => 'invalid')
        end
      end
    end

    describe '.from_default_file' do
      it 'loads settings from encrypted file first' do
        stub_const('Workato::Connector::Sdk::DEFAULT_SETTINGS_PATH', 'spec/fixtures/settings.yaml')
        stub_const('Workato::Connector::Sdk::DEFAULT_ENCRYPTED_SETTINGS_PATH', 'spec/fixtures/settings.yaml.enc')
        stub_const('Workato::Connector::Sdk::DEFAULT_MASTER_KEY_PATH', 'spec/fixtures/master.key')

        settings = described_class.from_default_file

        expect(settings).not_to be_empty
      end

      context 'when encrypted file does not exists' do
        it 'loads settings from encrypted file first' do
          stub_const('Workato::Connector::Sdk::DEFAULT_SETTINGS_PATH', 'spec/fixtures/settings.yaml')

          settings = described_class.from_default_file('My Invalid Connection')

          expect(settings).not_to be_empty
        end
      end

      context 'when no default files' do
        it 'creates an empty unencrypted settings' do
          settings = described_class.from_default_file

          expect(settings).to be_empty
        end
      end
    end

    describe '#update' do
      let(:expected_settings_yaml) do
        YAML.dump(
          {
            'My Valid Connection' => {
              'user' => 'user',
              'password' => 'password'
            },
            'My Invalid Connection' => {
              'user' => 'user',
              'password' => 'valid'
            }
          }
        )
      end

      context 'when encrypted file' do
        subject(:settings_store) do
          described_class.new(path: 'spec/fixtures/settings.yaml', encrypted: false, name: 'My Invalid Connection')
        end

        it 'saves new settings to file' do
          allow(::File).to receive(:write)

          settings_store.update(user: 'user', password: 'valid')

          expect(::File).to have_received(:write).with('spec/fixtures/settings.yaml', expected_settings_yaml)
        end
      end

      context 'when plain text' do
        subject(:settings_store) do
          described_class.new(path: 'spec/fixtures/settings.yaml.enc', encrypted: true, name: 'My Invalid Connection')
        end

        it 'saves new settings to file' do
          stub_const('Workato::Connector::Sdk::DEFAULT_MASTER_KEY_PATH', 'spec/fixtures/master.key')

          expect_any_instance_of(FixedEncryptedConfiguration).to receive(:write).with(expected_settings_yaml)
          settings_store.update(user: 'user', password: 'valid')
        end
      end
    end
  end
end
