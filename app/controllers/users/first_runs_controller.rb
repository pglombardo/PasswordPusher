# frozen_string_literal: true

class Users::FirstRunsController < Users::RegistrationsController
  before_action :prevent_repeats
  before_action :validate_boot_code, only: [:create]

  def create
    build_resource(sign_up_params)

    # Skip confirmation email notification and auto-confirm before saving
    resource.skip_confirmation_notification! if resource.respond_to?(:skip_confirmation_notification!)
    resource.skip_confirmation! if resource.respond_to?(:skip_confirmation!)

    if resource.save
      # Ensure user is confirmed (reload to get fresh state)
      resource.reload
      resource.confirm if resource.respond_to?(:confirm) && !resource.confirmed?

      # Clear the boot code after successful setup
      FirstRunBootCode.clear!

      # Sign up the user (which includes signing them in)
      sign_up(resource_name, resource)
      redirect_to after_sign_up_path_for(resource), notice: I18n._("Administrator account created successfully!")
    else
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource
    end
  end

  protected

  # Override to permit boot_code parameter
  def configure_permitted_parameters
    super
    devise_parameter_sanitizer.permit(:sign_up, keys: [:boot_code])
  end

  # Override to exclude boot_code from params passed to User model
  def sign_up_params
    params = super
    return params unless params

    params.except(:boot_code)
  end

  def build_resource(hash = {})
    super

    resource.admin = true
  end

  private

  def prevent_repeats
    return unless User.any?

    redirect_to root_url
  end

  def validate_boot_code
    boot_code = params.dig(:user, :boot_code) || params[:boot_code]

    unless FirstRunBootCode.valid?(boot_code)
      flash.now[:alert] = I18n._("Invalid or missing boot code. Please check the application logs for the boot code.")
      build_resource(sign_up_params)
      render :new, status: :unprocessable_content
      nil
    end
  end
end
