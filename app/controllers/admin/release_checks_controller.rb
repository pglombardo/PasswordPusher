# frozen_string_literal: true

module Admin
  class ReleaseChecksController < ::AdminController
    def create
      unless ReleaseCheck.enabled?
        redirect_back fallback_location: admin_root_path
        return
      end

      result = ReleaseCheck.refresh
      if result
        redirect_back fallback_location: admin_root_path, notice: _("Checked for updates.")
      else
        redirect_back fallback_location: admin_root_path,
          alert: _("Could not check for updates. Try again later.")
      end
    end

    def dismiss
      result = ReleaseCheck.cached
      version = params[:version].to_s.strip.delete_prefix("v")

      if result && !result.security_available? && version == result.latest.to_s
        cookies[ReleaseCheck::DISMISS_COOKIE] = {
          value: version,
          expires: 1.year.from_now,
          secure: Settings.secure_cookies,
          httponly: true,
          same_site: :lax
        }
      end

      redirect_back fallback_location: admin_root_path
    end
  end
end
