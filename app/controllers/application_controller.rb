# frozen_string_literal: true

class ApplicationController < ActionController::Base
  protect_from_forgery unless: -> { request.format.json? }
  add_flash_types :info, :error, :success, :warning
  before_action :configure_permitted_parameters, if: :devise_controller?

  include Pwpush::FirstRun
  include SetLocale

  before_action :enforce_mfa_if_required

  private

  def enforce_mfa_if_required
    return unless user_signed_in?
    return unless Settings.require_mfa
    return if current_user.otp_required_for_login?
    return if controller_path == "users/two_factor"
    return if controller_path == "users/sessions"

    redirect_to backup_codes_user_two_factor_path,
      alert: _("Two-factor authentication is required. Please set it up to continue.")
  end

  # To add extra fields to Devise registration, add the attribute names to `extra_keys`
  # See: https://stackoverflow.com/questions/64057147/attributes-not-saving-with-devise-and-accepts-nested-attributes-for
  def configure_permitted_parameters
    extra_keys = [:preferred_language]
    signup_keys = extra_keys + []
    devise_parameter_sanitizer.permit(:sign_up, keys: signup_keys)
    devise_parameter_sanitizer.permit(:account_update, keys: extra_keys)
    devise_parameter_sanitizer.permit(:accept_invitation, keys: extra_keys)
  end
end
