# frozen_string_literal: true

class Users::TwoFactorController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_otp_secret, except: [:destroy]
  before_action :ensure_backup_codes, except: [:destroy]

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
      redirect_to edit_user_registration_path, notice: _("Two-factor authentication is now enabled.")
    else
      flash.now[:alert] = _("Incorrect verification code.")
      render :verify, status: :unprocessable_content
    end
  end

  def destroy
    current_user.disable_totp!
    redirect_to edit_user_registration_path, status: :see_other, notice: _("Two-factor authentication has been disabled.")
  end

  private

  def ensure_otp_secret
    current_user.ensure_otp_secret!
  end

  def ensure_backup_codes
    return if Array(current_user.otp_backup_codes).any?

    current_user.generate_otp_backup_codes!
  end
end
