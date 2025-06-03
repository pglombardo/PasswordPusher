# frozen_string_literal: true

class Api::V1::PushesController < Api::BaseController
  include SetPushAttributes
  include LogEvents

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
      render template: "pushes/show", status: :ok
      return
    end

    # Passphrase handling
    if @push.passphrase.present?
      # JSON requests must pass the passphrase in the params
      has_passphrase = params[:passphrase] == @push.passphrase

      unless has_passphrase
        log_failed_passphrase(@push)

        # Passphrase hasn't been provided or is incorrect
        render json: {
          error: "That passphrase is incorrect.",
          message: "This push requires a passphrase. Please provide it using the 'passphrase' parameter (e.g. ?passphrase=mysecret)",
          status: :unauthorized
        }, status: :unauthorized
        return
      end
    end

    log_view(@push)
    expires_now

    render template: "pushes/show", status: :ok

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
    param :kind, %w[text file url qr], desc: "The kind of push to create. Defaults to 'text'.", required: false
  end
  formats ["JSON"]
  description <<-EOS
    == Creating a New Push

    Creates a new push (secret URL) containing the provided payload. The payload can be:

    * Text/password (default)
    * File attachments (requires authentication & subscription)
    * URLs
    * QR codes

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
        -H "X-User-Email: user@example.com" \\
        -H "X-User-Token: MyAPIToken" \\
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
      # These are used to determine the default kind based on the request path
      # for old push records. Their paths are generated based on their kind.
      # And, QR code pushes are created by using `/p/` path.
      # So, it is not necessary to check for a special path.
      @push.kind = if request.path.include?("/f.json")
        "file"
      elsif request.path.include?("/r.json")
        "url"
      elsif request.path.include?("/p.json") && push_params.key?(:files)
        "file"
      else
        "text"
      end
    end

    @push.user = current_user if user_signed_in?

    create_detect_deletable_by_viewer(@push, push_params)
    create_detect_retrieval_step(@push, push_params)

    if @push.save
      log_creation(@push)

      render template: "pushes/show", status: :created
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
    if @push.user != current_user
      render json: {error: t("pushes.not_owner_push")}, status: :forbidden
      return
    end

    @secret_url = helpers.secret_url(@push)
    render json: {views: @push.audit_logs}.to_json(except: %i[user_id push_id id])
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
        -H "X-User-Email: user@example.com" \\
        -H "X-User-Token: MyAPIToken" \\
        https://pwpush.com/p/fkwjfvhall92.json

    == Example Response

      {
        "expired": true,
        "expired_on": "2023-10-20T15:32:01Z"
      }

    == Language Specific Examples

    For language-specific examples and detailed API documentation, see:
    https://docs.pwpush.com/docs/json-api/
  EOS
  def destroy
    if (@push.user == current_user) || @push.deletable_by_viewer
      unless @push.expired?
        # Deletable by the owner or viewer
        @push.expire!
        log_expire(@push)
      end

      render template: "pushes/show", status: :ok
    else
      notice = t("pushes.expire.not_deletable")
      render json: {error: notice}, status: :unauthorized
    end
  end

  api :GET, "/p/active.json", "Retrieve your active pushes."
  formats ["JSON"]
  description <<-EOS
    == Active Pushes Retrieval

    Returns the list of pushes that are still active.

    == Example Request

      curl -X GET \\
        -H "X-User-Email: user@example.com" \\
        -H "X-User-Token: MyAPIToken" \\
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
      render json: {error: t("pushes.need_login_for_active")}, status: :unauthorized
      return
    end

    @pushes = Push.includes(:audit_logs)
      .where(user_id: current_user.id, expired: false)
      .page(params[:page])
      .order(created_at: :desc)

    render template: "pushes/index", status: :ok
  end

  api :GET, "/p/expired.json", "Retrieve your expired pushes."
  formats ["JSON"]
  description <<-EOS
    == Expired Pushes Retrieval

    Returns the list of pushes that have expired.

    == Example Request

      curl -X GET \\
        -H "X-User-Email: user@example.com" \\
        -H "X-User-Token: MyAPIToken" \\
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
      render json: {error: t("pushes.need_login_for_expired")}, status: :unauthorized
      return
    end

    @pushes = Push.includes(:audit_logs)
      .where(user_id: current_user.id, expired: true)
      .page(params[:page])
      .order(created_at: :desc)

    render template: "pushes/index", status: :ok
  end

  private

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
    if request.path.start_with?("/f")
      params.require(:file_push).permit(:name, :expire_after_days, :expire_after_views, :deletable_by_viewer,
        :retrieval_step, :payload, :note, :passphrase, files: [])
    elsif request.path.start_with?("/r")
      params.require(:url).permit(:name, :expire_after_days, :expire_after_views,
        :retrieval_step, :payload, :note, :passphrase)
    else
      # https://docs.pwpush.com/docs/json-api/#curl
      # curl -X POST -H "X-User-Email: <email>" -H "X-User-Token: MyAPIToken"
      # -F "password[payload]=my_secure_payload"
      # -F "password[note]=For New Employee ID 12345"
      # -F "password[files][]=@/path/to/file/file1.extension"
      # -F "password[files][]=@/path/to/file/file2.extension"
      # https://pwpush.com/p.json
      # There is a differences between the premium and OSS features.
      # It is allowed to create password pushes by using files on the premium one.
      # To respond same request, password[files] are allowed, but it will create a file push.
      #
      # More, kind can be used to create different kind pushes.
      params.require(:password).permit(:name, :kind, :expire_after_days, :expire_after_views, :deletable_by_viewer,
        :retrieval_step, :payload, :note, :passphrase, files: [])
    end
  rescue => e
    Rails.logger.error("Error in push_params: #{e.message}")

    raise e
  end
end
