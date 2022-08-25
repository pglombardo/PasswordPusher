class ApplicationController < ActionController::Base
  protect_from_forgery unless: -> { request.format.json? }
  around_action :set_locale_from_url

  def not_found
    raise ActionController::RoutingError.new(_('Not Found'))
  end

  # unless Rails.application.config.consider_all_requests_local
  #   rescue_from Exception, with: lambda { |exception| render_error 500, exception }
  #   rescue_from ActionController::RoutingError, ActionController::UnknownController,
  #         ::AbstractController::ActionNotFound, ActiveRecord::RecordNotFound,
  #         with: lambda { |exception| render_error 404, exception }
  # end
  # rescue_from ApplicationController::RoutingError, ApplicationController::UnknownController,
  #     ::AbstractController::ActionNotFound, ApplicationRecord::RecordNotFound,
  #     with: lambda { |exception| render_error 404, exception }

  private

  def render_error(status, exception)
    respond_to do |format|
      format.html { render template: "errors/error_#{status}", layout: 'layouts/application', status: status }
      format.all  { render nothing: true, status: status }
    end
  end
end
