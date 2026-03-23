# frozen_string_literal: true

class Users::PasswordsController < Devise::PasswordsController
  layout "login"

  # GET /resource/password/new
  # def new
  #   super
  # end

  # POST /resource/password
  # def create
  #   super
  # end

  # GET /resource/password/edit?reset_password_token=abcdef
  # def edit
  #   super
  # end

  # PUT /resource/password
  # def update
  #   super
  # end

  # protected

  # def after_resetting_password_path_for(resource)
  #   super(resource)
  # end

  # The path used after sending reset password instructions
  # def after_sending_reset_password_instructions_path_for(resource_name)
  #   super(resource_name)
  # end

  protected

  def sign_in_after_reset_password?
    return false unless Devise.sign_in_after_reset_password

    !resource.otp_required_for_login?
  end
end
