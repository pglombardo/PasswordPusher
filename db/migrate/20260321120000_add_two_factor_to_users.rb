# frozen_string_literal: true

class AddTwoFactorToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :otp_required_for_login, :boolean
    # Lockbox ciphertext for TOTP secret (plaintext virtual attribute: otp_secret)
    add_column :users, :otp_secret_ciphertext, :text
    add_column :users, :last_otp_timestep, :integer
    # HMAC-SHA256 hex digests of backup codes (never store plaintext codes)
    add_column :users, :otp_backup_code_digests, :text
  end
end
