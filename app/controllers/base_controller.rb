class BaseController < ApplicationController
  rescue_from ActionController::ParameterMissing do |exception|
    respond_to do |format|
      format.html { render plain: "Missing Parameters", status: :bad_request }
      format.any { head :bad_request }
    end
  end

  rescue_from ActionController::UnknownFormat do |exception|
    respond_to do |format|
      format.html { render plain: "Unsupported format", status: :unsupported_media_type }
      format.any { head :unsupported_media_type }
    end
  end

  rescue_from ActionController::BadRequest do |exception|
    Rails.logger.error "Invalid request parameters: #{exception.message}"
    respond_to do |format|
      format.html { render plain: "Invalid request parameters", status: :bad_request }
      format.json { render json: {error: "Invalid request parameters"}, status: :bad_request }
      format.any { head :bad_request }
    end
  end
end
