# frozen_string_literal: true

module Admin
  class CustomCssController < ::AdminController
    def edit
      @custom_css = SiteSetting.custom_css
    end

    def update
      SiteSetting.custom_css = params[:custom_css]
      redirect_to edit_admin_custom_css_path, notice: _("Custom CSS updated successfully.")
    rescue => e
      redirect_to edit_admin_custom_css_path, alert: _("Error updating CSS: %{error}") % {error: e.message}
    end
  end
end
