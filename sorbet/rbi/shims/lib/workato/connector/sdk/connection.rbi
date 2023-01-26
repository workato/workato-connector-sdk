# typed: strict
# frozen_string_literal: true

module Workato
  module Connector
    module Sdk
      module SorbetTypes
        OnSettingsUpdateProc = T.type_alias do
          T.proc.params(
            message: String,
            settings_before: SorbetTypes::SettingsHash,
            updater: T.proc.returns(T.nilable(HashWithIndifferentAccess))
          ).returns(T.nilable(HashWithIndifferentAccess))
        end
      end

      class Connection
        sig { returns(T.nilable(SorbetTypes::OnSettingsUpdateProc)) }
        def on_settings_update; end

        sig { params(obj: T.nilable(SorbetTypes::OnSettingsUpdateProc)).void }
        def on_settings_update=(obj); end

        class << self
          sig { returns(T.nilable(SorbetTypes::OnSettingsUpdateProc)) }
          def on_settings_update; end

          sig { params(obj: T.nilable(SorbetTypes::OnSettingsUpdateProc)).void }
          def on_settings_update=(obj); end
        end
      end
    end
  end
end
