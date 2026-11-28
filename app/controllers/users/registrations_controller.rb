# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  include EnforceRequiredMfa

  invisible_captcha only: :create

  layout "application", only: %i[edit update token regen_token]
  layout "login", except: %i[edit update token regen_token]

  after_action :prevent_browser_caching_of_token_page, only: %i[token regen_token]

  # before_action :configure_sign_up_params, only: [:create]
  # before_action :configure_account_update_params, only: [:update]

  # GET /resource/sign_up
  # def new
  #   super
  # end

  # POST /resource
  # def create
  #   super
  # end

  # GET /resource/edit
  # def edit
  #   super
  # end

  # PUT /resource
  # def update
  #   super
  # end

  # DELETE /resource
  def destroy
    # Call Devise's default destroy behavior
    super
  end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  # GET /resource/token
  def token
    if current_user.nil?
      redirect_to user_session_path
      return
    end

    unless current_user.has_authentication_token?
      @raw_authentication_token = current_user.regenerate_authentication_token!
    end
  end

  # DELETE /resource/token
  # Render the token in this response rather than stashing it in the CookieStore
  # session, which could be replayed to reveal the value again.
  def regen_token
    if current_user.nil?
      redirect_to user_session_path
    else
      @raw_authentication_token = current_user.regenerate_authentication_token!
      render :token
    end
  end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_up_params
  #   devise_parameter_sanitizer.permit(:sign_up, keys: [:attribute])
  # end

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_account_update_params
  #   devise_parameter_sanitizer.permit(:account_update, keys: [:attribute])
  # end

  # The path used after sign up.
  # def after_sign_up_path_for(resource)
  #   super(resource)
  # end

  def after_inactive_sign_up_path_for(resource)
    new_user_session_path
  end

  private

  def prevent_browser_caching_of_token_page
    response.headers["Cache-Control"] = "no-store"
  end

  # The path used after sign up for inactive accounts.
  # def after_inactive_sign_up_path_for(resource)
  #   super(resource)
  # end
end
