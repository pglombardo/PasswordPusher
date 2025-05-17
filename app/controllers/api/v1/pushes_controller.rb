# frozen_string_literal: true

require "securerandom"

class Api::V1::PushesController < Api::BaseController
  before_action :set_push, only: %i[show preview audit destroy]

  resource_description do
    name "Text Pushes"
    short "Interact directly with text pushes."
  end

  
  api :GET, "/p/active.json", "Retrieve your active pushes."
  formats ["JSON"]
  description <<-EOS
    == Active Pushes Retrieval

    Returns the list of pushes for your account that are still active.

    == Example Request

      curl -X GET \\
        -H "Authorization: Bearer MyAPIToken" \\
        https://pwpush.com/p/active.json

    == Example Response

        [
          {
            "url_token": "fkwjfvhall92",
            "created_at": "2023-10-20T15:32:01Z",
            "name": null,
            "expire_after_days": 7,
            "expire_after_views": 1,
            "expired": false,
            "days_remaining": 7,
            "views_remaining": 1,
            ...
          },
          ...
        ]
  EOS
  def active
    unless Settings.enable_logins
      redirect_to :root
      return
    end

    @pushes = Password.includes(:audit_logs)
      .where(user_id: current_user.id, expired: false)
      .page(params[:page])
      .order(created_at: :desc)

    json_parts = []
    @pushes.each do |push|
      json_parts << push.to_json(owner: true, payload: false)
    end
    render json: "[#{json_parts.join(",")}]"
  end


  api :GET, "/p/:url_token/audit.json", "Retrieve the audit log for a push."
  param :url_token, String, desc: "Secret URL token of a previously created push.", required: true
  formats ["JSON"]
  description <<-EOS
    == Push Audit Log Retrieval

    Returns the audit log for a push, containing an array of view events with metadata including:
    - IP address of viewer
    - User agent
    - Referrer URL
    - Timestamp
    - Event type (view, failed_view, expire, etc)

    Authentication is required. Only the owner of the push can retrieve its audit log.
    Requests for pushes not owned by the authenticated user will receive a 403 Forbidden response.

    == Example Request

      curl -X GET \\
        -H "X-User-Email: user@example.com" \\
        -H "X-User-Token: MyAPIToken" \\
        https://pwpush.com/p/fk27vnslkd/audit.json

    == Example Response

      {
        "views": [
          {
            "ip": "x.x.x.x",
            "user_agent": "Mozilla/5.0...",
            "referrer": "https://example.com",
            "created_at": "2023-10-20T15:32:01Z",
            "successful": true,
            ...
          }
        ]
      }
  EOS
  def audit
    if @push.user_id != current_user.id
      render json: {error: "That push doesn't belong to you."}
      return
    end

    @secret_url = helpers.secret_url(@push)

    render json: {views: @push.views}.to_json(except: %i[user_id password_id id])
  end


  api :POST, "/p.json", "Create a new push."
  param :password, Hash, "Push details", required: true do
    param :payload, String, desc: "The URL encoded password or secret text to share.", required: true
    param :passphrase, String, desc: "Require recipients to enter this passphrase to view the created push."
    param :name, String, desc: "Visible only to the push creator.", allow_blank: true
    param :note, String, desc: "If authenticated, the URL encoded note for this push.  Visible only to the push creator.", allow_blank: true
    param :expire_after_days, Integer, desc: "Expire secret link and delete after this many days."
    param :expire_after_views, Integer, desc: "Expire secret link and delete after this many views."
    param :deletable_by_viewer, %w[true false], desc: "Allow users to delete passwords once retrieved."
    param :retrieval_step, %w[true false], desc: "Helps to avoid chat systems and URL scanners from eating up views."
  end
  param :account_id, Integer, desc: "The account ID to associate the push with. See: https://docs.pwpush.com/docs/json-api/#multiple-accounts", required: false
  formats ["JSON"]
  description <<-EOS
    == Creating a New Push

    Creates a new push (secret URL) containing the provided payload.

    === Required Parameters

    The push must be created with a payload parameter containing the secret content.
    All other parameters are optional and will use system defaults if not specified.

    === Expiration Settings

    Pushes can be configured to expire after:

    * A number of views (expire_after_views)
    * A number of days (expire_after_days)
    * Both views and days (first trigger wins)

    === Security Options

    * Passphrase protection requires viewers to enter a secret phrase
    * Retrieval step helps prevent automated URL scanners from burning views
    * Deletable by viewer allows recipients to manually expire the push

    == Example Request

      curl -X POST \\
        -H "Authorization: Bearer MyAPIToken" \\
        -H "Content-Type: application/json" \\
        -d '{"password": {"payload": "secret_text"}}' \\
        https://pwpush.com/p.json

    == Example Response

      {
        "url_token": "fkwjfvhall92",
        "created_at": "2023-10-20T15:32:01Z",
        "expires_at": "2023-10-20T15:32:01Z",
        "views_remaining": 10,
        "passphrase": null,
        "note": null,
        ...
      }
  EOS
  def create
    # Require authentication if allow_anonymous is false
    # See config/settings.yml
    authenticate_user! if Settings.enable_logins && !Settings.allow_anonymous

    # params[:password] has to exist
    # params[:password] has to be a ActionController::Parameters (Hash)
    password_param = params.fetch(:password, {})
    unless password_param.respond_to?(:fetch)
      render json: {error: "No password, text or files provided."}, status: :unprocessable_entity
      return
    end

    # params[:password][:payload] || params[:password][:payload] has to exist
    # params[:password][:payload] can't be blank
    # params[:password][:payload] must have a length between 1 and 1 megabyte
    payload_param = password_param.fetch(:payload, "")
    unless payload_param.is_a?(String) && payload_param.length.between?(1, 1.megabyte)
      render json: {error: "Payload length must be between 1 and 1_048_576."}, status: :unprocessable_entity
      return
    end

    @push = Password.new
    @push.expire_after_days = params[:password].fetch(:expire_after_days, Settings.pw.expire_after_days_default)
    @push.expire_after_views = params[:password].fetch(:expire_after_views, Settings.pw.expire_after_views_default)
    @push.user_id = current_user.id if user_signed_in?
    @push.url_token = SecureRandom.urlsafe_base64(rand(8..14)).downcase

    create_detect_deletable_by_viewer(@push, params)
    create_detect_retrieval_step(@push, params)

    @push.payload = params[:password][:payload]
    @push.name = params[:password][:name]
    @push.note = params[:password].fetch(:note, "")
    @push.passphrase = params[:password].fetch(:passphrase, "")

    @push.validate!

    if @push.save
      render json: @push, status: :created
    else
      render json: @push.errors, status: :unprocessable_entity
    end
  end

  
  api :DELETE, "/p/:url_token.json", "Expire a push: delete the payload and expire the secret URL."
  param :url_token, String, desc: "Secret URL token of a previously created push.", required: true
  formats ["JSON"]
  description <<-EOS
    == Push Expiration

    Expires a push immediately.  Must be authenticated & owner of the push _or_ the push must
    have been created with _deleteable_by_viewer_.

    == Example Request

      curl -X DELETE \\
        -H "Authorization: Bearer MyAPIToken" \\
        https://pwpush.com/p/fkwjfvhall92.json

    == Example Response

      {
        "expired": true,
        "expired_on": "2024-12-10T15:32:01Z"
      }
  EOS
  def destroy
    # Check if the push is deletable by the viewer or if the user is the owner
    if @push.deletable_by_viewer == false && @push.user_id != current_user&.id
      render json: {error: _("That push is not deletable by viewers and does not belong to you.")}, status: :unprocessable_entity
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


  api :GET, "/p/expired.json", "Retrieve your expired pushes."
  formats ["JSON"]
  description <<-EOS
    == Expired Pushes Retrieval

    Returns the list of pushes for your account that have expired.

    == Example Request

      curl -X GET \\
        -H "Authorization: Bearer MyAPIToken" \\
        https://pwpush.com/p/expired.json

    == Example Response

      [
        {
          "url_token": "fkwjfvhall92",
          "created_at": "2023-10-20T15:32:01Z",
          "expires_on": "2023-10-23T15:32:01Z",
          "expire_after_days": 7,
          "expire_after_views": 1,
          "expired": true,
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

    @pushes = Password.includes(:audit_logs)
      .where(user_id: current_user.id, expired: true)
      .page(params[:page])
      .order(created_at: :desc)

    json_parts = []
    @pushes.each do |push|
      json_parts << push.to_json(owner: true, payload: false)
    end
    render json: "[#{jsaon_parts.join(",")}]"
  end


  api :GET, "/p/:url_token/preview.json", "Helper endpoint to retrieve the fully qualified secret URL of a push."
  param :url_token, String, desc: "Secret URL token of a previously created push.", required: true
  formats ["JSON"]
  description <<-EOS
    == Preview a Push

    This method retrieves the preview URL of a push.  This is useful for getting the
    fully qualified URL of a push before sharing it with others.

    === Example Request

      curl -X GET \\
        -H "Authorization: Bearer MyAPIToken" \\
        https://pwpush.com/p/fk27vnslkd/preview.json

    === Example Response

      {
        "url": "https://pwpush.com/p/fk27vnslkd"
      }
  EOS
  def preview
    @secret_url = helpers.secret_url(@push)
    @qr_code = helpers.qr_code(@secret_url)
    render json: {url: @secret_url}, status: :ok
  end

  api :GET, "/p/:url_token.json", "Retrieve a push."
  param :url_token, String, desc: "Secret URL token of a previously created push.", required: true
  formats ["JSON"]
  description <<-EOS
    == Retrieving a Push

    Retrieves a push and its payload. If the push is active, this request will count as a view and be logged in the audit log.

    === Security Features

    * Passphrase protection - Requires a passphrase to view.

      Provide the passphrase as a GET parameter: ?passphrase=xxx

    === Example Request

      curl -X GET \\
        -H "Authorization: Bearer MyAPIToken" \\
        https://pwpush.com/p/fk27vnslkd.json

    === Example Response

      {
        "payload": "secret_text",
        "passphrase": null,
        "note": "By user initiated request from the user@example.com account",
        "expire_after_days": null,
        "expire_after_views": null,
        "deletable_by_viewer": false,
        "retrieval_step": false,
        ...
      }
  EOS
  def show
    # This password may have expired since the last view.  Validate the password
    # expiration before doing anything.
    @push.validate!

    if @push.expired
      log_view(@push)
      render json: @push.to_json(payload: true)
      return
    else
      @payload = @push.payload
    end

    # Passphrase handling
    if !@push.passphrase.nil? && @push.passphrase.present?
      # Construct the passphrase cookie name
      name = "#{@push.url_token}-p"

      # The passphrase can be passed in the params or in the cookie (default)
      # JSON requests must pass the passphrase in the params
      has_passphrase = params.fetch(:passphrase,
        nil) == @push.passphrase || cookies[name] == @push.passphrase_ciphertext

      unless has_passphrase
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

    # Optionally blur the text payload
    @blur_css_class = Settings.pw.enable_blur ? "spoiler" : ""

    render json: @push.to_json(payload: true)

    # Expire if this is the last view for this push
    @push.expire unless @push.views_remaining.positive?
  end


  private

  ##
  # log_view
  #
  # Record that a view is being made for a password
  #
  def log_view(password, manual_expiration: false)
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

    record[:successful] = password.expired ? false : true

    password.views.create(record)
    password
  end

  # Since determining this value between and HTML forms and JSON API requests can be a bit
  # tricky, we break this out to it's own function.
  def create_detect_retrieval_step(password, params)
    if Settings.pw.enable_retrieval_step == true
      if params[:password].key?(:retrieval_step)
        # User form data or json API request: :deletable_by_viewer can
        # be 'on', 'true', 'checked' or 'yes' to indicate a positive
        user_rs = params[:password][:retrieval_step].to_s.downcase
        password.retrieval_step = %w[on yes checked true].include?(user_rs)
      else
        password.retrieval_step = if request.format.html?
          # HTML Form Checkboxes: when NOT checked the form attribute isn't submitted
          # at all so we set false - NOT deletable by viewers
          false
        else
          # The JSON API is implicit so if it's not specified, use the app
          # configured default
          Settings.pw.retrieval_step_default
        end
      end
    else
      # RETRIEVAL_STEP_ENABLED not enabled
      password.retrieval_step = false
    end
  end

  # Since determining this value between and HTML forms and JSON API requests can be a bit
  # tricky, we break this out to it's own function.
  def create_detect_deletable_by_viewer(password, params)
    if Settings.pw.enable_deletable_pushes == true
      if params[:password].key?(:deletable_by_viewer)
        # User form data or json API request: :deletable_by_viewer can
        # be 'on', 'true', 'checked' or 'yes' to indicate a positive
        user_dvb = params[:password][:deletable_by_viewer].to_s.downcase
        password.deletable_by_viewer = %w[on yes checked true].include?(user_dvb)
      else
        password.deletable_by_viewer = if request.format.html?
          # HTML Form Checkboxes: when NOT checked the form attribute isn't submitted
          # at all so we set false - NOT deletable by viewers
          false
        else
          # The JSON API is implicit so if it's not specified, use the app
          # configured default
          Settings.pw.deletable_pushes_default
        end
      end
    else
      # DELETABLE_PASSWORDS_ENABLED not enabled
      password.deletable_by_viewer = false
    end
  end

  def set_push
    @push = Password.includes(:audit_logs).find_by!(url_token: params[:id])
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
    respond_to do |format|
      format.json { render json: {error: "not-found"}.to_json, status: :not_found }
      format.any { head :not_acceptable }
    end
  end

  def password_params
    params.require(:password).permit(:payload, :expire_after_days, :expire_after_views,
      :retrieval_step, :deletable_by_viewer, :name, :note)
  end
end
