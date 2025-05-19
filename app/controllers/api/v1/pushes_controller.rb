# frozen_string_literal: true

require "securerandom"

class Api::V1::PushesController < Api::BaseController
  helper UrlsHelper

  before_action :set_push, only: %i[show preview audit destroy]

  resource_description do
    name "Pushes"
    short "Interact directly with pushes."
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
            "html_url": "https://pwpush.com/p/fkwjfvhall92",
            "json_url": "https://pwpush.com/p/fkwjfvhall92.json",
            "created_at": "2023-10-20T15:32:01Z",
            "expires_at": "2023-10-20T15:32:01Z",
            ...
          },
          ...
        ]

    == Language Specific Examples

    For language-specific examples and detailed API documentation, see:
    https://docs.pwpush.com/docs/json-api/
  EOS
  def active
    unless Settings.enable_logins
      render json: {error: _("You must be logged in to view your active pushes.")}, status: :unauthorized
      return
    end

    @pushes = Push.includes(:audit_logs)
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
            "kind": "view"
          }
        ]
      }

    == Language Specific Examples

    For language-specific examples and detailed API documentation, see:
    https://docs.pwpush.com/docs/json-api/
  EOS
  def audit
    if @push.user_id != current_user.id
      render json: {error: "That push doesn't belong to you."}
      return
    end

    @secret_url = helpers.secret_url(@push)

    render json: {views: @push.audit_logs}.to_json(except: %i[user_id push_id id])
  end

  api :POST, "/p.json", "Create a new push."
  param :password, Hash, "Push details", required: true do
    param :payload, String, desc: "The URL encoded password or secret text to share.", required: true
    param :files, Array, desc: "File(s) to upload and attach to the push."
    param :passphrase, String, desc: "Require recipients to enter this passphrase to view the created push."
    param :name, String, desc: "A name shown in the dashboard, notifications and emails.", allow_blank: true
    param :note, String, desc: "If authenticated, the URL encoded note for this push.  Visible only to the push creator.", allow_blank: true
    param :expire_after_days, Integer, desc: "Expire secret link and delete after this many days."
    param :expire_after_views, Integer, desc: "Expire secret link and delete after this many views."
    param :deletable_by_viewer, %w[true false], desc: "Allow users to delete passwords once retrieved."
    param :retrieval_step, %w[true false], desc: "Helps to avoid chat systems and URL scanners from eating up views."
    param :kind, %w[text file url], desc: "The kind of push to create. Defaults to 'text'.", required: false
  end
  param :account_id, Integer, desc: "The account ID to associate the push with. See: https://docs.pwpush.com/docs/json-api/#multiple-accounts", required: false
  formats ["JSON"]
  description <<-EOS
    == Creating a New Push

    Creates a new push (secret URL) containing the provided payload. The payload can be:

    * Text/password (default)
    * File attachments (requires authentication & subscription)
    * URLs

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

    == Language Specific Examples

    See language specific examples in the docs: https://docs.pwpush.com/docs/json-api/

    == Example Request

      curl -X POST \\
        -H "Authorization: Bearer MyAPIToken" \\
        -H "Content-Type: application/json" \\
        -d '{"password": {"payload": "secret_text"}}' \\
        https://pwpush.com/p.json

    == Example Response

      {
        "url_token": "fkwjfvhall92",
        "html_url": "https://pwpush.com/p/fkwjfvhall92",
        "json_url": "https://pwpush.com/p/fkwjfvhall92.json",
        "created_at": "2023-10-20T15:32:01Z",
        "expires_at": "2023-10-20T15:32:01Z",
        "views_remaining": 10,
        "views_total": 10,
        "files": [],
        "passphrase": null,
        "name": null,
        "note": null,
        "expire_after_days": null,
      }
  EOS
  def create
    # Require authentication if allow_anonymous is false
    # See config/settings.yml
    authenticate_user! if Settings.enable_logins && !Settings.allow_anonymous

    @push = Push.new(push_params)
    
    if !push_params[:kind].present?
      @push.kind = if request.path.include?("/f.json")
        "file"
      elsif request.path.include?("/r.json")
        "url"
      else
        "text"
      end
    end

    @push.user_id = current_user.id if user_signed_in?

    # MIGRATE - ask
    # This method is not available for url
    # So, if it is Url push, it is skipped
    unless @push.url?
      create_detect_deletable_by_viewer(@push, push_params)
    end
    create_detect_retrieval_step(@push, push_params)

    # MIGRATE - ask
    # Is this needed?
    @push.note = push_params.fetch(:note, "")
    @push.passphrase = push_params.fetch(:passphrase, "")

    @push.validate!

    user_id = current_user.id if user_signed_in?
    # MIGRATE - ask
    # Why log_event is not used? Is selecting ip here different than selecting ip in log_event
    @push.audit_logs.build(kind: :creation, user_id:, ip: request.remote_ip,
      user_agent: request.env["HTTP_USER_AGENT"], referrer: request.env["HTTP_REFERER"])

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
        "expired_on": "2023-10-20T15:32:01Z"
      }

    == Language Specific Examples

    For language-specific examples and detailed API documentation, see:
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

    @push.expire!
    log_expire(@push)

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
          "html_url": "https://pwpush.com/p/fkwjfvhall92",
          "json_url": "https://pwpush.com/p/fkwjfvhall92.json",
          "created_at": "2023-10-20T15:32:01Z",
          "expires_at": "2023-10-20T15:32:01Z",
          ...
        },
        ...
      ]

    == Language Specific Examples

    For language-specific examples and detailed API documentation, see:
    https://docs.pwpush.com/docs/json-api/
  EOS
  def expired
    unless Settings.enable_logins
      redirect_to :root
      return
    end

    @pushes = Push.includes(:audit_logs)
      .where(user_id: current_user.id, expired: true)
      .page(params[:page])
      .order(created_at: :desc)

    json_parts = []
    @pushes.each do |push|
      json_parts << push.to_json(owner: true, payload: false)
    end
    render json: "[#{json_parts.join(",")}]"
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

    == Language Specific Examples

    For language-specific examples and detailed API documentation, see:
    https://docs.pwpush.com/docs/json-api/
  EOS
  def preview
    @secret_url = helpers.secret_url(@push)
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

    == Language Specific Examples

    For language-specific examples and detailed API documentation, see:
    https://docs.pwpush.com/docs/json-api/
  EOS
  def show
    # This push may have expired since the last view.  Validate the url
    # expiration before doing anything.
    @push.validate!

    if @push.expired
      log_view(@push)
      render json: @push.to_json(payload: true)
      return
    end

    # MIGRATE - ask
    # Previously, pushes has some steps related to cookies. Will it be added or not?
    if @push.passphrase.present?
      # JSON requests must pass the passphrase in the params
      has_passphrase = params.fetch(:passphrase, nil) == @push.passphrase

      unless has_passphrase
        # Passphrase hasn't been provided or is incorrect
        render json: {
          error: "Authentication required",
          message: "This push requires a passphrase. Please provide it using the 'passphrase' parameter (e.g. ?passphrase=mysecret)",
          status: :unauthorized
        }, status: :unauthorized
        return
      end
    end

    log_view(@push)
    expires_now

    render json: @push.to_json(payload: true)


    # If files are attached, we can't expire immediately as the viewer still needs
    # to download the files.  In the case of files, this push will be expired on the
    # next ExpirePushesJob run or next view attempt.  Whichever comes first.
    if !@push.files.attached? && !@push.views_remaining.positive?
      # Expire if this is the last view for this push
      @push.expire!
    end
  end

  private

  ##
  # log_view
  #
  # Record that a view is being made for a url
  #
  def log_view(push)
    if push.expired
      log_event(push, :failed_view)
    else
      log_event(push, :view)
    end
    push
  end

  def log_failed_passphrase(push)
    log_event(push, :failed_passphrase)
  end

  def log_expire(push)
    log_event(push, :expire)
  end
  
  def log_event(push, kind)
    ip = request.env["HTTP_X_FORWARDED_FOR"].nil? ? request.env["REMOTE_ADDR"] : request.env["HTTP_X_FORWARDED_FOR"]

    # Limit retrieved values to 256 characters
    user_agent = request.env["HTTP_USER_AGENT"].to_s[0, 255]
    referrer = request.env["HTTP_REFERER"].to_s[0, 255]

    push.audit_logs.create(kind: kind, user: current_user, ip:, user_agent:, referrer:)
    nil
  end

  # Since determining this value between and HTML forms and JSON API requests can be a bit
  # tricky, we break this out to it's own function.
  def create_detect_retrieval_step(push, params)
    if settings_for(push).enable_retrieval_step == true
      if params[:push].key?(:retrieval_step)
        # User form data or json API request: :deletable_by_viewer can
        # be 'on', 'true', 'checked' or 'yes' to indicate a positive
        user_rs = params[:push][:retrieval_step].to_s.downcase
        push.retrieval_step = %w[on yes checked true].include?(user_rs)
      else
        push.retrieval_step = if request.format.html?
          # HTML Form Checkboxes: when NOT checked the form attribute isn't submitted
          # at all so we set false - NOT deletable by viewers
          false
        else
          # The JSON API is implicit so if it's not specified, use the app
          # configured default
          settings_for(push).retrieval_step_default
        end
      end
    else
      # RETRIEVAL_STEP_ENABLED not enabled
      push.retrieval_step = false
    end
  end

  def create_detect_deletable_by_viewer(push, params)
    if settings_for(push).enable_deletable_pushes == true
      if params[:push].key?(:deletable_by_viewer)
        # User form data or json API request: :deletable_by_viewer can
        # be 'on', 'true', 'checked' or 'yes' to indicate a positive
        user_dvb = params[:push][:deletable_by_viewer].to_s.downcase
        push.deletable_by_viewer = %w[on yes checked true].include?(user_dvb)
      else
        push.deletable_by_viewer = if request.format.html?
          # HTML Form Checkboxes: when NOT checked the form attribute isn't submitted
          # at all so we set false - NOT deletable by viewers
          false
        else
          # The JSON API is implicit so if it's not specified, use the app
          # configured default
          settings_for(push).deletable_pushes_default
        end
      end
    else
      # DELETABLE_PASSWORDS_ENABLED not enabled
      push.deletable_by_viewer = false
    end
  end

  def set_push
    @push = Push.includes(:audit_logs).find_by!(url_token: params[:id])
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
    end
  end
  
  def push_params
    sanitized_params = if params.key?(:file_push)
      params.require(:file_push).permit(:name, :expire_after_days, :expire_after_views, :deletable_by_viewer,
        :retrieval_step, :payload, :note, :passphrase, files: [])
    elsif params.key?(:url)
      params.require(:url).permit(:name, :expire_after_days, :expire_after_views, :deletable_by_viewer,
        :retrieval_step, :payload, :note, :passphrase, files: [])
    elsif params.key?(:password)
      params.require(:password).permit(:name, :kind, :expire_after_days, :expire_after_views, :deletable_by_viewer,
        :retrieval_step, :payload, :note, :passphrase, files: [])
    else
      return nil
    end

    sanitized_params
  rescue => e
    Rails.logger.error("Error in push_params: #{e.message}")
    nil
  end
end
