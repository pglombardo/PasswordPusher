# frozen_string_literal: true

require "securerandom"

class Api::V1::PushesController < Api::BaseController
  include SetPushAttributes
  include LogEvents

  helper UrlsHelper

  before_action :set_current_kind
  before_action :set_push, only: %i[show preview audit destroy]

  resource_description do
    name "Pushes"
    short "Interact directly with pushes."
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
    @push.check_limits

    if @push.expired
      log_view(@push)
      render json: @push.to_json(payload: true)
      return
    end

    if @push.passphrase.present?
      # JSON requests must pass the passphrase in the params
      has_passphrase = params[:passphrase] == @push.passphrase

      unless has_passphrase
        # Passphrase hasn't been provided or is incorrect
        # Passphrase hasn't been provided or is incorrect
        render json: {error: "This push has a passphrase that was incorrect or not provided."}
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
    @push.kind = @current_kind

    @push.user_id = current_user.id if user_signed_in?

    create_detect_deletable_by_viewer(@push, push_params)
    create_detect_retrieval_step(@push, push_params)

    if @push.save
      log_creation(@push)

      render json: @push, status: :created
    else
      render json: @push.errors, status: :unprocessable_entity
    end
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

    # Get the raw logs excluding creation and failed_passphrase events
    logs = @push.audit_logs.where.not(kind: %i[creation failed_passphrase])

    # Transform the logs into the desired format
    json_logs = logs.map do |log|
      kind_value = log.kind_before_type_cast
      except_key = if @push.file?
        :file_push_id
      elsif @push.url?
        :url_id
      else
        :password_id
      end
      
      {
        password_id: nil,
        ip: log.ip,
        user_agent: log.user_agent,
        referrer: log.referrer,
        successful: [AuditLog.kinds[:view], AuditLog.kinds[:expire]].include?(kind_value),
        created_at: log.created_at,
        updated_at: log.updated_at,
        kind: (kind_value == AuditLog.kinds[:expire]) ? 1 : 0,
        file_push_id: nil,
        url_id: nil
      }.except(except_key)
    end

    render json: {views: json_logs}
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

    if @push.expire
      log_expire(@push)
      render json: @push, status: :ok
    else
      render json: @push.errors, status: :unprocessable_entity
    end
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
      .where(kind: @current_kind, user_id: current_user.id, expired: false)
      .page(params[:page])
      .order(created_at: :desc)

    json_parts = []
    @pushes.each do |push|
      json_parts << push.to_json(owner: true, payload: false)
    end
    render json: "[#{json_parts.join(",")}]"
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
      .where(kind: @current_kind, user_id: current_user.id, expired: true)
      .page(params[:page])
      .order(created_at: :desc)

    json_parts = []
    @pushes.each do |push|
      json_parts << push.to_json(owner: true, payload: false)
    end
    render json: "[#{json_parts.join(",")}]"
  end

  private

  def set_push
    @push = Push.includes(:audit_logs).find_by!(url_token: params[:id], kind: @current_kind)
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
    if @current_kind == "file"
      params.require(:file_push).permit(:name, :expire_after_days, :expire_after_views, :deletable_by_viewer,
        :retrieval_step, :payload, :note, :passphrase, files: [])
    elsif @current_kind == "url"
      params.require(:url).permit(:name, :expire_after_days, :expire_after_views,
        :retrieval_step, :payload, :note, :passphrase)
    elsif @current_kind == "text"
      params.require(:password).permit(:name, :expire_after_days, :expire_after_views, :deletable_by_viewer,
        :retrieval_step, :payload, :note, :passphrase)
    end
  rescue => e
    Rails.logger.error("Error in push_params: #{e.message}")

    raise e
  end

  def set_current_kind
    @current_kind = if request.path.start_with?("/f")
      "file"
    elsif request.path.start_with?("/r")
      "url"
    elsif request.path.start_with?("/p")
      "text"
    end
  end
end
