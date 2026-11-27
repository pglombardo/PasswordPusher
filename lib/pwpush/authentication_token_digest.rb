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

    # Last 4 characters, but only when that is not the entire token.
    def hint_for(token)
      value = token.to_s
      return if value.length <= 4

      value.last(4)
    end

    def masked(hint)
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
