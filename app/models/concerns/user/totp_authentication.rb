# frozen_string_literal: true

# Time-based one-time passwords (TOTP) for web sign-in, with backup recovery codes.
# `last_otp_timestep` stores the Unix timestamp returned by ROTP on the last successful
# TOTP verification (used as ROTP's `after:` to prevent token reuse).
# Backup codes are stored serialized in the database; protect the database accordingly.
module User::TotpAuthentication
  extend ActiveSupport::Concern

  included do
    serialize :otp_backup_codes, coder: ActiveRecord::Coders::JSON.new, type: Array
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
    update!(otp_required_for_login: false, otp_secret: nil, otp_backup_codes: [], last_otp_timestep: nil)
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
      token_time = totp.verify(normalized, after: last_otp_timestep, drift_behind: 15)
      if token_time
        update!(last_otp_timestep: token_time.to_i)
        return true
      end
    end

    consume_backup_code!(normalized)
  end

  def generate_otp_backup_codes!
    codes = []
    16.times do
      codes << SecureRandom.hex(5)
    end
    update!(otp_backup_codes: codes)
    codes
  end

  private

  def verify_backup_code?(code)
    Array(otp_backup_codes).include?(code)
  end

  def consume_backup_code!(code)
    list = Array(otp_backup_codes)
    return false unless list.delete(code)

    update!(otp_backup_codes: list)
    true
  end
end
