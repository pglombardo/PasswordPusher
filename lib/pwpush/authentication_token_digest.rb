# frozen_string_literal: true

module Pwpush
  # Deterministic unsalted SHA-256 for API tokens so lookup stays an indexed +find_by+.
  # Tokens are high-entropy random strings (Devise.friendly_token).
  module AuthenticationTokenDigest
    module_function

    def hexdigest(token)
      return if token.blank?

      OpenSSL::Digest::SHA256.hexdigest(token.to_s)
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
