# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  include Devise::Controllers::Rememberable

  layout "login"

  # Prepend so this runs before Devise::SessionsController#create (warden.authenticate! would
  # otherwise sign in with password only and bypass the OTP step).
  # Register reject last so it runs first (prepended callbacks run in reverse order).
  prepend_before_action :authenticate_with_two_factor, only: [:create]
  prepend_before_action :reject_when_logins_disabled, only: [:new, :create]

  # before_action :configure_sign_in_params, only: [:create]

  # GET /resource/sign_in
  # def new
  #   super
  # end

  # POST /resource/sign_in
  # def create
  #   super
  # end

  # DELETE /resource/sign_out
  # def destroy
  #   super
  # end

  def authenticate_with_two_factor
    if sign_in_params[:email].present?
      self.resource = resource_class.find_for_database_authentication(
        email: sign_in_params[:email]
      )
      clear_otp_user_from_session
      start_two_factor_if_required if resource&.otp_required_for_login?
    elsif session[:otp_user_id].present?
      complete_two_factor_sign_in
    end
  end

  def start_two_factor_if_required
    return unless resource.valid_password?(sign_in_params[:password])

    session[:remember_me] = Devise::TRUE_VALUES.include?(sign_in_params[:remember_me])
    session[:otp_user_id] = resource.id
    render :otp, status: :unprocessable_content
  end

  def complete_two_factor_sign_in
    self.resource = resource_class.find_by(id: session[:otp_user_id])
    unless resource
      clear_otp_user_from_session
      redirect_to new_user_session_path, alert: _("Session expired. Please sign in again.")
      return
    end

    if resource.verify_and_consume_otp!(params[:otp_attempt])
      want_remember_me = session.delete(:remember_me)
      clear_otp_user_from_session
      remember_me(resource) if want_remember_me
      set_flash_message!(:notice, :signed_in)
      sign_in(resource, event: :authentication)
      respond_with resource, location: after_sign_in_path_for(resource)
    else
      flash.now[:alert] = _("Incorrect verification code.")
      render :otp, status: :unprocessable_content
    end
  end

  def clear_otp_user_from_session
    session.delete(:otp_user_id)
    session.delete(:remember_me)
  end

  # after_sign_out_path_for
  #
  # This method is called after the user has signed out.
  # Ensure the session data is cleared and the session cookie is deleted.
  #
  def reject_when_logins_disabled
    return unless Settings.disable_logins

    head :not_found
  end

  def after_sign_out_path_for(resource_or_scope)
    reset_session  # Explicitly clear the session data
    cookies.delete("_PasswordPusher_session") # Delete the session cookie
    root_path      # Redirect to the root path after logout
  end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end
end
