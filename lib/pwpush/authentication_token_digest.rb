# frozen_string_literal: true

module Pwpush
  # Deterministic HMAC-SHA256 for API tokens so lookup stays an indexed +find_by+.
  #
  # The HMAC key is +PWPUSH_API_TOKEN_HMAC_KEY+ (or +PWPUSH_API_TOKEN_HMAC_KEY_FILE+)
  # when set, otherwise a key derived from +secret_key_base+. Rotating
  # +SECRET_KEY_BASE+ without a dedicated HMAC key invalidates every API token.
  module AuthenticationTokenDigest
    PURPOSE = "Pwpush::TokenAuthentication"
    HMAC_KEY_ENV = "PWPUSH_API_TOKEN_HMAC_KEY"

    module_function

    def hexdigest(token)
      return if token.blank?

      OpenSSL::HMAC.hexdigest("SHA256", hmac_key, token.to_s)
    end

    def hmac_key
      explicit = PasswordPusher::EnvOrFile.read(HMAC_KEY_ENV)
      return explicit if explicit.present?

      OpenSSL::HMAC.digest("SHA256", Rails.application.secret_key_base, PURPOSE)
    end

    def hint_for(token)
      token.to_s.last(4).presence
    end

    def masked(hint)
      return if hint.blank?

      "••••#{hint}"
    end

    # Converts rows that still have plaintext +authentication_token+ into digest + hint.
    # Used by the hashing migration and by tests that simulate a pre-upgrade database.
    def backfill!(records)
      records.each do |record|
        token = record.read_attribute(:authentication_token)
        next if token.blank?

        record.update_columns(
          authentication_token_digest: hexdigest(token),
          authentication_token_hint: hint_for(token),
          authentication_token_legacy: true,
          authentication_token: nil
        )
      end
    end
  end
end
