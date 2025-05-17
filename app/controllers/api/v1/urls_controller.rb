# frozen_string_literal: true

require "securerandom"

class Api::V1::UrlsController < Api::BaseController
  helper UrlsHelper

  before_action :set_push, only: %i[show preview audit destroy]

  resource_description do
    name "URL Pushes"
    short "Interact directly with URL pushes.  This feature (and corresponding API) is currently in beta."
  end



  api :GET, "/r/active.json", "Retrieve your active URL pushes."
  formats ["json"]
  description <<-EOS
    == Active URL Pushes Retrieval

    Returns the list of URL pushes that you previously pushed which are still active.

    == Example Request

      curl -X GET \\
        -H "Authorization: Bearer MyAPIToken" \\
        https://pwpush.com/r/active.json

    == Example Response

      [
        {
          "url_token": "fkwjfvhall92",
          "name": null,
          "created_at": "2023-10-20T15:32:01Z",
          "expires_on": "2023-10-23T15:32:01Z",
          ...
        },
        ...
      ]
  EOS
  def active
    unless Settings.enable_logins
      render json: {error: _("You must be logged in to view your active pushes.")}, status: :unauthorized
      return
    end

    @pushes = Url.includes(:views)
      .where(user_id: current_user.id, expired: false)
      .page(params[:page])
      .order(created_at: :desc)

    json_parts = []
    @pushes.each do |push|
      json_parts << push.to_json(owner: true, payload: false)
    end
    render json: "[#{json_parts.join(",")}]"
  end


  api :GET, "/r/:url_token/audit.json", "Retrieve the audit log for a push."
  param :url_token, String, desc: "Secret URL token of a previously created push.", required: true
  formats ["json"]
  description <<-EOS
    == URL Push Audit

    Retrieves the audit log for a push.

    == Example Request

      curl -X GET \\
        -H "Authorization: Bearer MyAPIToken" \\
        https://pwpush.com/r/fk27vnslkd/audit.json

    == Example Response

      [
        {
          "ip": "127.0.0.1",
          "referrer": "https://example.com",
          "created_at": "2023-10-20T15:32:01Z",
          "successful": true,
          ...
        },
        ...
      ]
  EOS
  def audit
    if @push.user_id != current_user.id
      render json: {error: "That push doesn't belong to you."}
      return
    end

    @secret_url = helpers.secret_url(@push)

    render json: {views: @push.views}.to_json(except: %i[user_id url_id id])
  end

  api :POST, "/r.json", "Create a new URL push."
  param :url, Hash, "Push details", required: true do
    param :payload, String, desc: "The URL encoded URL to redirect to.", required: true
    param :passphrase, String, desc: "Require recipients to enter this passphrase to view the created push."
    param :name, String, desc: "Visible only to the push creator.", allow_blank: true
    param :note, String,
      desc: "If authenticated, the URL encoded note for this push.  Visible only to the push creator.", allow_blank: true
    param :expire_after_days, Integer, desc: "Expire secret link and delete after this many days."
    param :expire_after_views, Integer, desc: "Expire secret link and delete after this many views."
    param :retrieval_step, %w[true false], desc: "Helps to avoid chat systems and URL scanners from eating up views."
  end
  formats ["json"]
  description <<-EOS
    == URL Push Creation

    Creates a new URL push with the given payload and details.

    == Example Request

    curl -X POST \\
      -H "Authorization: Bearer MyAPIToken" \\
      -d "url[payload]=https://example.com" \\
      -d "url[expire_after_days]=2" \\
      -d "url[expire_after_views]=10" \\
      https://pwpush.com/r.json

    == Example Response

      {
        "url_token": "quyul5r5w18",
        "created_at": "2023-10-20T15:32:01Z",
        "expire_after_days": 2,
        "expire_after_views": 10,
        ...
      }
  EOS
  def create
    # Require authentication if allow_anonymous is false
    # See config/settings.yml
    authenticate_user! if Settings.enable_logins && !Settings.allow_anonymous

    begin
      @push = Url.new(url_params)
    rescue ActionController::ParameterMissing
      render json: {error: "No URL or note provided."}, status: :unprocessable_entity
      return
    end

    url_param = params.fetch(:url, {})
    payload_param = url_param.fetch(:payload, "")

    unless helpers.valid_url?(payload_param)
      msg = _("Invalid URL: Must have a valid URI scheme.")
      render json: {error: msg}, status: :unprocessable_entity
      return
    end

    @push.expire_after_days = params[:url].fetch(:expire_after_days, Settings.url.expire_after_days_default)
    @push.expire_after_views = params[:url].fetch(:expire_after_views, Settings.url.expire_after_views_default)
    @push.user_id = current_user.id if user_signed_in?
    @push.url_token = SecureRandom.urlsafe_base64(rand(8..14)).downcase

    create_detect_retrieval_step(@push, params)

    @push.payload = params[:url][:payload]
    @push.name = params[:url][:name]
    @push.note = params[:url][:note] if params[:url].fetch(:note, "").present?
    @push.passphrase = params[:url].fetch(:passphrase, "")

    @push.validate!

    if @push.save
      render json: @push, status: :created
    else
      render json: @push.errors, status: :unprocessable_entity
    end
  end


  api :DELETE, "/r/:url_token.json", "Expire a push: delete the payload and expire the secret URL."
  param :url_token, String, desc: "Secret URL token of a previously created push.", required: true
  formats ["json"]
  description <<-EOS
    == URL Push Expiration

    Expires a push immediately.  Must be authenticated & owner of the push _or_ the push must
    have been created with _deleteable_by_viewer_.

    == Example Request

      curl -X DELETE \\
        -H "Authorization: Bearer MyAPIToken" \\
        https://pwpush.com/r/fkwjfvhall92.json

    == Example Response

      {
        "expired": true,
        "expired_on": "2023-10-23T15:32:01Z",
        ...
      }
  EOS
  def destroy
    # Check ownership
    if @push.user_id != current_user&.id
      render json: {error: _("That push does not belong to you.")}
      return
    end

    if @push.expired
      render json: {error: _("That push is already expired.")}, status: :unprocessable_entity
      return
    end

    log_view(@push, manual_expiration: true)

    @push.expired = true
    @push.payload = nil
    @push.deleted = true
    @push.expired_on = Time.zone.now

    if @push.save
      render json: @push, status: :ok
    else
      render json: @push.errors, status: :unprocessable_entity
    end
  end


  api :GET, "/r/expired.json", "Retrieve your expired URL pushes."
  formats ["json"]
  description <<-EOS
    == Expired URL Pushes Retrieval

    Returns the list of URL pushes that you previously pushed which have expired.

    == Example Request

      curl -X GET \\
        -H "Authorization: Bearer MyAPIToken" \\
        https://pwpush.com/r/expired.json

    == Example Response

      [
        {
          "url_token": "fkwjfvhall92",
          "created_at": "2023-10-20T15:32:01Z",
          "expires_on": "2023-10-23T15:32:01Z",
          ...
        },
        ...
      ]
  EOS
  def expired
    unless Settings.enable_logins
      redirect_to :root
      return
    end

    @pushes = Url.includes(:views)
      .where(user_id: current_user.id, expired: true)
      .page(params[:page])
      .order(created_at: :desc)

    json_parts = []
    @pushes.each do |push|
      json_parts << push.to_json(owner: true, payload: false)
    end
    render json: "[#{json_parts.join(",")}]"
  end


  api :GET, "/r/:url_token/preview.json", "Helper endpoint to retrieve the fully qualified secret URL of a push."
  param :url_token, String, desc: "Secret URL token of a previously created push.", required: true
  formats ["json"]
  description <<-EOS
    == URL Push Preview

    Retrieves the fully qualified secret URL of a push.

    == Example Request

      curl -X GET \\
        -H "Authorization: Bearer MyAPIToken" \\
        https://pwpush.com/r/fk27vnslkd/preview.json

    == Example Response

      {
        "url": "https://pwpush.com/r/fk27vnslkd"
      }
  EOS
  def preview
    @secret_url = helpers.secret_url(@push)
    @qr_code = helpers.qr_code(@secret_url)

    render json: {url: @secret_url}, status: :ok
  end


  api :GET, "/r/:url_token.json", "Retrieve a URL push."
  param :url_token, String, desc: "Secret URL token of a previously created push.", required: true
  formats ["json"]
  description <<-EOS
    == URL Push Retrieval

    Retrieves a push including it's payload and details.  If the push is still active,
    this will burn a view and the transaction will be logged in the push audit log.

    == Example Request

      curl -X GET \\
        -H "Authorization: Bearer MyAPIToken" \\
        https://pwpush.com/r/fk27vnslkd.json

    == Example Response

      {
        "expire_after_days": 2,
        "expire_after_views": 5,
        "expired": false,
        "url_token": "quyul5r5w18",
        "payload": "https://example.com",
        ...
      }
  EOS
  def show
    # This url may have expired since the last view.  Validate the url
    # expiration before doing anything.
    @push.validate!

    if @push.expired
      log_view(@push)
      render json: @push.to_json(payload: true)
      return
    end

    # Passphrase handling
    if @push.passphrase.present?
      # Construct the passphrase cookie name
      name = "#{@push.url_token}-r"

      # The passphrase can be passed in the params or in the cookie (default)
      # JSON requests must pass the passphrase in the params
      has_correct_passphrase =
        params.fetch(:passphrase, nil) == @push.passphrase || cookies[name] == @push.passphrase_ciphertext

      if !has_correct_passphrase
        # Passphrase hasn't been provided or is incorrect
        # Redirect to the passphrase page
        render json: {error: "This push has a passphrase that was incorrect or not provided."}
        return
      end

      # Delete the cookie
      cookies.delete name
    end

    log_view(@push)
    expires_now

    render json: @push.to_json(payload: true)

    @push.expire unless @push.views_remaining.positive?
  end

  private

  ##
  # log_view
  #
  # Record that a view is being made for a url
  #
  def log_view(url, manual_expiration: false)
    record = {}

    # 0 - standard user view
    # 1 - manual expiration
    record[:kind] = manual_expiration ? 1 : 0

    record[:user_id] = current_user.id if user_signed_in?
    record[:ip] =
      request.env["HTTP_X_FORWARDED_FOR"].nil? ? request.env["REMOTE_ADDR"] : request.env["HTTP_X_FORWARDED_FOR"]

    # Limit retrieved values to 256 characters
    record[:user_agent] = request.env["HTTP_USER_AGENT"].to_s[0, 255]
    record[:referrer] = request.env["HTTP_REFERER"].to_s[0, 255]

    record[:successful] = url.expired ? false : true

    url.views.create(record)
    url
  end

  # Since determining this value between and HTML forms and JSON API requests can be a bit
  # tricky, we break this out to it's own function.
  def create_detect_retrieval_step(url, params)
    if Settings.url.enable_retrieval_step == true
      if params[:url].key?(:retrieval_step)
        # User form data or json API request: :retrieval_step can
        # be 'on', 'true', 'checked' or 'yes' to indicate a positive
        user_rs = params[:url][:retrieval_step].to_s.downcase
        url.retrieval_step = %w[on yes checked true].include?(user_rs)
      else
        url.retrieval_step = if request.format.html?
          # HTML Form Checkboxes: when NOT checked the form attribute isn't submitted
          # at all so we set false - NO retrieval step
          false
        else
          # The JSON API is implicit so if it's not specified, use the app
          # configured default
          Settings.url.retrieval_step_default
        end
      end
    else
      # RETRIEVAL_STEP_ENABLED not enabled
      url.retrieval_step = false
    end
  end

  def set_push
    @push = Url.includes(:views).find_by!(url_token: params[:id])
  rescue ActiveRecord::RecordNotFound
    # Showing a 404 reveals that this Secret URL never existed
    # which is an information leak (not a secret anymore)
    # We also don't want data in general. We entirely delete old pushes that:
    # 1. have expired (payloads already deleted long ago)
    # 2. are anonymous/not linked to a user account (audit log not needed)
    # Old, expired & anonymous pushes have no value to anybody.
    # When not found, show the 'expired' page so even very old secret URLs
    # when clicked they will be accurate - this secret URL has expired.
    # No easy fix for JSON unfortunately as we don't have a record to show.
    render json: {error: "not-found"}, status: :not_found
  end

  def url_params
    params.require(:url).permit(:payload, :expire_after_days, :expire_after_views, :retrieval_step, :name, :note, :passphrase)
  end
end
