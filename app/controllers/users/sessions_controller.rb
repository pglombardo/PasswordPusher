# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  layout "login"

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

  # after_sign_out_path_for
  #
  # This method is called after the user has signed out.
  # Ensure the session data is cleared and the session cookie is deleted.
  #
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
