# frozen_string_literal: true

class Users::TwoFactorController < ApplicationController
  before_action :authenticate_user!
  # show only redirects; do not generate secrets/codes on that hit.
  before_action :ensure_otp_secret, except: %i[destroy show]
  before_action :ensure_backup_codes, except: %i[destroy show]

  def show
    redirect_to edit_user_registration_path
  end

  def backup_codes
  end

  def verify
  end

  def create
    if current_user.verify_and_consume_otp!(params[:code])
      current_user.enable_totp!
      session.delete(:otp_backup_codes_plaintext)
      redirect_to edit_user_registration_path, notice: _("Two-factor authentication is now enabled.")
    else
      flash.now[:alert] = _("Incorrect verification code.")
      render :verify, status: :unprocessable_content
    end
  end

  def destroy
    current_user.disable_totp!
    session.delete(:otp_backup_codes_plaintext)
    redirect_to edit_user_registration_path, status: :see_other, notice: _("Two-factor authentication has been disabled.")
  end

  private

  def ensure_otp_secret
    current_user.ensure_otp_secret!
  end

  def ensure_backup_codes
    if Array(current_user.otp_backup_code_digests).empty?
      plaintexts = current_user.generate_otp_backup_codes!
      session[:otp_backup_codes_plaintext] = plaintexts
    end
    @otp_backup_codes_display = session[:otp_backup_codes_plaintext]
  end
end
