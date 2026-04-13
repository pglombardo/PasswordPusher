# frozen_string_literal: true

module EnforceRequiredMfa
  extend ActiveSupport::Concern

  included do
    before_action :enforce_mfa_if_required
  end

  private

  def enforce_mfa_if_required
    return unless user_signed_in?
    return unless Settings.require_mfa
    return if current_user.otp_required_for_login?
    return if controller_path == "users/two_factor"
    return if controller_path == "users/sessions"

    message = _("Two-factor authentication is required. Please set it up to continue.")

    if request.format.json?
      render json: {error: message}, status: :forbidden
      return
    end

    redirect_to backup_codes_user_two_factor_path, alert: message
  end
end
