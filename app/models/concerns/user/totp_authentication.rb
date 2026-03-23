# frozen_string_literal: true

# Time-based one-time passwords (TOTP) for web sign-in, with backup recovery codes.
# `last_otp_timestep` stores the Unix timestamp returned by ROTP on the last successful
# TOTP verification (used as ROTP's `after:` to prevent token reuse).
# `otp_secret` is encrypted at rest (Lockbox). Backup codes are stored as HMAC digests only;
# plaintext codes are shown once via session (see Users::TwoFactorController).
module User::TotpAuthentication
  extend ActiveSupport::Concern

  included do
    has_encrypted :otp_secret

    serialize :otp_backup_code_digests, coder: ActiveRecord::Coders::JSON.new, type: Array
  end

  class_methods do
    # Used by tests and to build digests; same algorithm as instance digesting.
    def digest_otp_backup_code(user_id, code)
      OpenSSL::HMAC.hexdigest(
        "SHA256",
        Rails.application.secret_key_base,
        "#{user_id}:#{code.to_s.strip.downcase}"
      )
    end
  end

  def totp_issuer
    Settings.brand&.title.presence || "Password Pusher"
  end

  def ensure_otp_secret!
    return if otp_secret.present?

    update!(otp_secret: ROTP::Base32.random)
  end

  def enable_totp!
    update!(otp_required_for_login: true)
  end

  def disable_totp!
    update!(
      otp_required_for_login: false,
      otp_secret: nil,
      otp_backup_code_digests: [],
      last_otp_timestep: nil
    )
  end

  def totp
    raise ArgumentError, "otp_secret is blank" if otp_secret.blank?

    ROTP::TOTP.new(otp_secret, issuer: totp_issuer)
  end

  def totp_provisioning_uri
    totp.provisioning_uri(email)
  end

  def totp_manual_entry_secret
    otp_secret
  end

  # Verifies a 6-digit TOTP or a backup code, then consumes it (single-use).
  def verify_and_consume_otp!(code)
    return false if code.blank?

    normalized = code.to_s.strip

    if otp_secret.present?
      with_lock do
        reload # fresh last_otp_timestep; lock prevents concurrent TOTP replays
        token_time = totp.verify(normalized, after: last_otp_timestep, drift_behind: 15)
        if token_time
          update!(last_otp_timestep: token_time.to_i)
          return true
        end
      end
    end

    consume_backup_code!(normalized)
  end

  # Returns plaintext codes once; persists only digests. Caller should stash plaintext in session for display.
  def generate_otp_backup_codes!
    plaintexts = 16.times.map { SecureRandom.hex(5) }
    digests = plaintexts.map { |p| self.class.digest_otp_backup_code(id, p) }
    update!(otp_backup_code_digests: digests)
    plaintexts
  end

  private

  def consume_backup_code!(code)
    normalized = code.to_s.strip.downcase
    candidate = self.class.digest_otp_backup_code(id, normalized)
    digests = Array(otp_backup_code_digests)
    match_index = nil
    digests.each_with_index do |stored, i|
      next unless stored.bytesize == candidate.bytesize

      if ActiveSupport::SecurityUtils.secure_compare(stored, candidate)
        match_index = i
        break
      end
    end
    return false unless match_index

    digests.delete_at(match_index)
    update!(otp_backup_code_digests: digests)
    true
  end
end
