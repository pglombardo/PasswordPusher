class Api::BaseController < ApplicationController
  prepend_before_action :require_api_authentication

  helper :all

  private

  def require_api_authentication
    return if user_signed_in?

    if (user = user_from_token)
      sign_in user, store: false

    elsif params["controller"] == "api/v1/version"
      # Version endpoint is public
      nil

    elsif request.headers.key?("Authorization") || request.headers.key?("X-User-Token")
      # The user is trying to authenticate with a bad token
      head :unauthorized

    elsif request.path.start_with?("/p")
      if %w[audit active expired].include?(params["action"])
        # These paths require a valid token
        head :unauthorized
      end

    elsif request.path.start_with?("/f")
      if %w[create audit active expired].include?(params["action"])
        # These paths require a valid token
        head :unauthorized
      end

    elsif request.path.start_with?("/r")
      if %w[create audit active expired].include?(params["action"])
        # These paths require a valid token
        head :unauthorized
      end
    else
      head :unauthorized
    end
  end

  def token_from_header
    # Legacy PWPUSH API token
    if request.headers.key?("X-User-Email") && request.headers.key?("X-User-Token")
      return request.headers["X-User-Token"]
    end

    # Authorization: Bearer <token>
    request.headers.fetch("Authorization", "").split(" ").last
  end

  def user_from_token
    api_token = token_from_header
    return nil if api_token.blank?

    User.find_by(authentication_token: token_from_header)
  end

  rescue_from ActionController::ParameterMissing do |exception|
    respond_to do |format|
      format.json { render json: {error: exception.message}, status: :bad_request }
    end
  end
end
