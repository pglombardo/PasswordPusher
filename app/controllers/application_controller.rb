class ApplicationController < ActionController::Base
  protect_from_forgery

  def not_found
    raise ActionController::RoutingError.new('Not Found')
  end
  
  def server_error
    raise ActionController::ActionControllerError.new('Server Error')
  end
  
  def unkonw_host_error(host)
    error_message = "Unknown host >>" + host + "<<; not in config"
    raise ActionController::ActionControllerError.new("Eroor 500 - unkown host " + request.host + " not in config")
  end

  # unless Rails.application.config.consider_all_requests_local
  #   rescue_from Exception, with: lambda { |exception| render_error 500, exception }
  #   rescue_from ActionController::RoutingError, ActionController::UnknownController,
  #         ::AbstractController::ActionNotFound, ActiveRecord::RecordNotFound,
  #         with: lambda { |exception| render_error 404, exception }
  # end
  rescue_from ActionController::RoutingError,
      ::AbstractController::ActionNotFound, ActiveRecord::RecordNotFound,
      with: lambda { |exception| log_error 404, exception }

  rescue_from ActionController::ActionControllerError,
      with: lambda { |exception| log_error 500, exception }

  private
  def log_error(status, exception)
	source = "Error #{status.to_s} at " << Time.new.strftime("%F %T %z") << " with message \r\n\t" << exception.message
    logger.debug source
	render_error(status, exception)
  end
  
  def render_error(status, exception)
    respond_to do |format|
      format.html { render template: "errors/error_#{status}", layout: 'layouts/application', status: status }
      format.all  { render nothing: true, status: status }
    end
  end
end