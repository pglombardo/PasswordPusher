# frozen_string_literal: true

class Users::FirstRunsController < Users::RegistrationsController
  invisible_captcha only: :create,
    timestamp_enabled: Rails.env.production?,
    spinner_enabled: Rails.env.production?
  before_action :prevent_repeats
  before_action :validate_boot_code, only: [:create]

  def new
    build_resource
    set_minimum_password_length
    respond_with resource
  end

  def create
    build_resource(sign_up_params)

    # Skip confirmation email notification and auto-confirm before saving
    resource.skip_confirmation_notification! if resource.respond_to?(:skip_confirmation_notification!)
    resource.skip_confirmation! if resource.respond_to?(:skip_confirmation!)

    if resource.save
      # Ensure user is confirmed (reload to get fresh state)
      resource.reload
      resource.confirm if resource.respond_to?(:confirm) && !resource.confirmed?
      # Sign up the user (which includes signing them in)
      sign_up(resource_name, resource)
      redirect_to after_sign_up_path_for(resource), notice: _("Administrator account created successfully!")
      # Clear the boot code after the entire success flow completes
      FirstRunBootCode.clear!
    else
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource
    end
  end

  protected

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
      flash.now[:alert] = _("Invalid or missing boot code. Please check the application logs for the boot code.")
      build_resource(sign_up_params)
      render :new, status: :unprocessable_content
    end
  end
end
