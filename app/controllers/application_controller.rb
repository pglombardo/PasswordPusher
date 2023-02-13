class ApplicationController < ActionController::Base
  protect_from_forgery unless: -> { request.format.json? }
  around_action :set_locale_from_url

  add_flash_types :info, :error, :success, :warning

  def not_found
    raise ActionController::RoutingError.new(_('Not Found'))
  end

  private

  def render_error(status, exception)
    respond_to do |format|
      format.html { render template: "errors/error_#{status}", layout: 'layouts/application', status: status }
      format.all  { render nothing: true, status: status }
    end
  end
end
