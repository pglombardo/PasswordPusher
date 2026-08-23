class Api::BaseController < ApplicationController
  # Maximum `page` query param for paginated API list endpoints (bounds OFFSET cost).
  API_MAX_PAGE = 200
  # Fixed page size for paginated API list endpoints.
  API_PAGE_SIZE = 50

  prepend_before_action :require_api_authentication

  helper :all

  private

  # Sets RFC 5988 Link and X-* pagination headers on the response.
  # Does not alter the JSON body. Call only on successful paginated responses.
  #
  # @param page [Integer] current page number
  # @param per_page [Integer] page size (typically API_PAGE_SIZE)
  # @param total [Integer] total matching records
  def set_pagination_headers(page:, per_page:, total:)
    total = total.to_i
    per_page = per_page.to_i
    page = page.to_i
    total_pages = (per_page.positive? && total.positive?) ? (total.to_f / per_page).ceil : 0

    response.set_header("X-Page", page.to_s)
    response.set_header("X-Per-Page", per_page.to_s)
    response.set_header("X-Total", total.to_s)
    response.set_header("X-Total-Pages", total_pages.to_s)

    link_parts = []
    if total_pages.positive?
      link_parts << %(<#{pagination_page_url(1)}>; rel="first")
      link_parts << %(<#{pagination_page_url(total_pages)}>; rel="last")
      link_parts << %(<#{pagination_page_url(page - 1)}>; rel="prev") if page > 1
      link_parts << %(<#{pagination_page_url(page + 1)}>; rel="next") if page < total_pages
    end

    response.set_header("Link", link_parts.join(", ")) if link_parts.any?
  end

  def pagination_page_url(page_number)
    query = request.query_parameters.merge("page" => page_number.to_s)
    "#{request.base_url}#{request.path}?#{query.to_query}"
  end

  # Validates and sanitizes the page parameter for pagination (rejects page > API_MAX_PAGE).
  # Returns the validated page number or renders an error response.
  #
  # @return [Integer, nil] validated page number or nil if error rendered
  def validate_page_parameter
    begin
      page = Integer(params[:page] || 1)
      page = [page, 1].max  # Ensure minimum of 1
    rescue ArgumentError, TypeError
      render json: {error: "Invalid page parameter"}, status: :bad_request
      return nil
    end

    if page > API_MAX_PAGE
      render json: {error: "Invalid page parameter"}, status: :bad_request
      return nil
    end

    page
  end

  def require_api_authentication
    return if user_signed_in?

    if (user = user_from_token)
      sign_in user, store: false

    elsif %w[api/v1/version api/v2/version].include?(params["controller"])
      # Version endpoints are public
      nil

    elsif request.headers.key?("Authorization") || request.headers.key?("X-User-Token")
      # The user is trying to authenticate with a bad token
      head :unauthorized

    elsif !Settings.allow_anonymous
      # When anonymous access is disabled, API endpoints require authentication.
      head :unauthorized

    elsif params["controller"] == "api/v2/pushes"
      if %w[audit active expired notify_emails].include?(params["action"])
        # These v2 endpoints require a valid token
        head :unauthorized
      end

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

    User.find_by(authentication_token: api_token)
  end

  rescue_from ActionController::ParameterMissing do |exception|
    respond_to do |format|
      format.json { render json: {error: exception.message}, status: :bad_request }
    end
  end
end
