# frozen_string_literal: true

module Workato::Connector::Sdk
  RSpec.describe Settings do
    describe '.from_file' do
      it 'loads settings as hash' do
        settings = described_class.from_file('spec/fixtures/settings.yaml')

        expect(settings).to eq('My Valid Connection' => {
                                 'user' => 'user',
                                 'password' => 'password'
                               },
                               'My Invalid Connection' => {
                                 'user' => 'user',
                                 'password' => 'invalid'
                               })
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
        settings = described_class.from_encrypted_file('spec/fixtures/settings.yaml.enc',
                                                       'spec/fixtures/master.key')
        expect(settings).to eq('My Valid Connection' => {
                                 'user' => 'user',
                                 'password' => 'password'
                               },
                               'My Invalid Connection' => {
                                 'user' => 'user',
                                 'password' => 'invalid'
                               })
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

            expect(settings).to_not be_empty
          end
        end

        context 'when ENV has DEFAULT_MASTER_KEY_ENV variable set' do
          it 'loads settings as hash' do
            allow(ENV).to receive(:[]).with(DEFAULT_MASTER_KEY_ENV).and_return('d113939d9dd3b4af7ff58b6c3013b348')

            settings = described_class.from_encrypted_file('spec/fixtures/settings.yaml.enc')

            expect(settings).to_not be_empty
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
  end
end
