class BaseController < ApplicationController
  rescue_from ActionController::UnknownFormat do |exception|
    respond_to do |format|
      format.html { render plain: "Unsupported format", status: :unsupported_media_type }
      format.any { head :unsupported_media_type }
    end
  end
end
