# frozen_string_literal: true

require "securerandom"

class Api::V1::FilePushesController < Api::BaseController
  helper FilePushesHelper

  before_action :set_push, only: %i[show preview audit destroy]

  resource_description do
    name "File Pushes"
    short "Interact directly with file pushes."
  end



  api :GET, "/f/active.json", "Retrieve your active file pushes."
  formats ["JSON"]
  description <<-EOS
    == Active File Pushes Retrieval

    Returns the list of file pushes that you previously pushed which are still active.

    == Example Request

      curl -X GET \\
        -H "Authorization: Bearer MyAPIToken" \\
        https://pwpush.com/f/active.json

    == Example Response

      [
        {
          "url_token": "fkwjfvhall92",
          "created_at": "2023-10-20T15:32:01Z",
          "expires_on": "2023-10-23T15:32:01Z",
          "name": null,
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

    @pushes = FilePush.includes(:views)
      .where(user_id: current_user.id, expired: false)
      .page(params[:page])
      .order(created_at: :desc)

    json_parts = []
    @pushes.each do |push|
      json_parts << push.to_json(owner: true, payload: false)
    end
    render json: "[#{json_parts.join(",")}]"
  end
  

  api :GET, "/f/:url_token/audit.json", "Retrieve the audit log for a push."
  param :url_token, String, desc: "Secret URL token of a previously created push.", required: true
  formats ["JSON"]
  description <<-EOS
    == File Push Audit

    Retrieves the audit log for a push.

    == Example Request

      curl -X GET \\
        -H "Authorization: Bearer MyAPIToken" \\
        https://pwpush.com/f/fk27vnslkd/audit.json

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

    render json: {views: @push.views}.to_json(except: %i[user_id file_push_id id])
  end


  api :POST, "/f.json", "Create a new file push."
  param :file_push, Hash, "Push details", required: true do
    param :payload, String, desc: "The URL encoded secret text to share.", required: true
    param :passphrase, String, desc: "Require recipients to enter this passphrase to view the created push."
    param :name, String, desc: "Visible only to the push creator.", allow_blank: true
    param :note, String,
      desc: "If authenticated, the URL encoded note for this push.  Visible only to the push creator.", allow_blank: true
    param :expire_after_days, Integer, desc: "Expire secret link and delete after this many days."
    param :expire_after_views, Integer, desc: "Expire secret link and delete after this many views."
    param :deletable_by_viewer, %w[true false], desc: "Allow users to delete the push once retrieved."
    param :retrieval_step, %w[true false],
      desc: "Helps to avoid chat systems and URL scanners from eating up views."
  end
  formats ["JSON"]
  description <<-EOS
    == File Push Creation

    Creates a new file push with the given payload and files.

    == Example Request

      curl -X POST \\
        -H "Authorization: Bearer MyAPIToken" \\
        -F "file_push[files][]=@/path/to/file/file1.extension" \\
        -F "file_push[files][]=@/path/to/file/file2.extension" \\
        https://pwpush.com/f.json

    == Example Response

      {
        "url_token": "quyul5r5w18",
        "created_at": "2023-10-20T15:32:01Z",
        "expire_after_days": 2,
        "expire_after_views": 5,
        ...
      }
  EOS
  def create
    # Require authentication if allow_anonymous is false
    # See config/settings.yml
    authenticate_user! if Settings.enable_logins && !Settings.allow_anonymous

    @push = FilePush.new(file_push_params)

    if file_push_params.key?(:files) &&
        file_push_params[:files].count { |e| e != "" } > Settings.files.max_file_uploads
      msg = t("pushes.form.upload_limit", count: Settings.files.max_file_uploads)
      render json: {error: msg}, status: :unprocessable_entity
      return
    end

    @push.expire_after_days ||= Settings.files.expire_after_days_default
    @push.expire_after_views ||= Settings.files.expire_after_views_default

    @push.user_id = current_user.id if user_signed_in?
    @push.url_token = SecureRandom.urlsafe_base64(rand(8..14)).downcase

    create_detect_deletable_by_viewer(@push, file_push_params)
    create_detect_retrieval_step(@push, file_push_params)

    @push.validate!

    if @push.save
      render json: @push, status: :created
    else
      render json: @push.errors, status: :unprocessable_entity
    end
  end


  api :DELETE, "/f/:url_token.json", "Expire a push: delete the files, payload and expire the secret URL."
  param :url_token, String, desc: "Secret URL token of a previously created push.", required: true
  formats ["JSON"]
  description <<-EOS
    == File Push Expiration

    Expires a push immediately.  Must be authenticated & owner of the push _or_ the push must
    have been created with _deleteable_by_viewer_.

    == Example Request

      curl -X DELETE \\
        -H "Authorization: Bearer MyAPIToken" \\
        https://pwpush.com/f/fkwjfvhall92.json

    == Example Response

      {
        "expired": true,
        "expired_on": "2023-10-23T15:32:01Z",
        ...
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
    @push.files.purge
    @push.expired_on = Time.zone.now

    if @push.save
      render json: @push, status: :ok
    else
      render json: @push.errors, status: :unprocessable_entity
    end
  end


  api :GET, "/f/expired.json", "Retrieve your expired file pushes."
  formats ["JSON"]
  description <<-EOS
    == Expired File Pushes Retrieval

    Returns the list of expired file pushes.

    == Example Request

      curl -X GET \\
        -H "Authorization: Bearer MyAPIToken" \\
        https://pwpush.com/f/expired.json

    == Example Response

      [
        {
          "url_token": "fkwjfvhall92",
          "created_at": "2023-10-20T15:32:01Z",
          "expires_on": "2023-10-23T15:32:01Z",
          ...
        },
      ]
  EOS
  def expired
    unless Settings.enable_logins
      render json: {error: _("You must be logged in to view your expired pushes.")}, status: :unauthorized
      return
    end

    @pushes = FilePush.includes(:views)
      .where(user_id: current_user.id, expired: true)
      .page(params[:page])
      .order(created_at: :desc)

    json_parts = []
    @pushes.each do |push|
      json_parts << push.to_json(owner: true, payload: false)
    end
    render json: "[#{json_parts.join(",")}]"
  end


  api :GET, "/f/:url_token/preview.json", "Helper endpoint to retrieve the fully qualified secret URL of a push."
  param :url_token, String, desc: "Secret URL token of a previously created push.", required: true
  formats ["JSON"]
  description <<-EOS
    == File Push Preview

    Retrieves the fully qualified secret URL of a push.

    == Example Request

      curl -X GET \\
        -H "Authorization: Bearer MyAPIToken" \\
        https://pwpush.com/f/fk27vnslkd/preview.json

    == Example Response

      {
        "url": "https://pwpush.com/f/fk27vnslkd"
      }
  EOS
  def preview
    @secret_url = helpers.secret_url(@push)
    @qr_code = helpers.qr_code(@secret_url)

    render json: {url: @secret_url}, status: :ok
  end
  

  api :GET, "/f/:url_token.json", "Retrieve a file push."
  param :url_token, String, desc: "Secret URL token of a previously created push.", required: true
  formats ["JSON"]
  description <<-EOS
    == File Push Retrieval

    Retrieves a file push including it's payload and details.  If the push is still active,
    this will burn a view and the transaction will be logged in the push audit log.

    == Example Request

      curl -X GET \\
        -H "Authorization: Bearer MyAPIToken" \\
        https://pwpush.com/f/fk27vnslkd.json

    == Example Response

      {
        "expire_after_days": 2,
        "expire_after_views": 5,
        "expired": false,
        "url_token": "quyul5r5w18",
        "files": '{"file1.extension":"/pfb/redirect/eyJfcmFpbHMiOnsiZGF0YSI6MywicHVyIjoiYmxvYl9pZCJ9fQ==--acf3b59f1884a16ef5d178848c32af856338064f/file1.extension","file2.extension":"/pfb/redirect/eyJfcmFpbHMiOnsiZGF0YSI6NCwicHVyIjoiYmxvYl9pZCJ9fQ==--34b10a5eca9026f8cc41bbd71c4d684abbe607bf/file2.extension"}'
        ...
      }

      Note: The files attached to the push are listed as a string of JSON with filenames and paths only.  This will be improved in v2 of the API.

      {
        "file1.extension": "/pfb/redirect/eyJfcmFpbHMiOnsiZGF0YSI6MywicHVyIjoiYmxvYl9pZCJ9fQ==--acf3b59f1884a16ef5d178848c32af856338064f/file1.extension",
        "file2.extension": "/pfb/redirect/eyJfcmFpbHMiOnsiZGF0YSI6NCwicHVyIjoiYmxvYl9pZCJ9fQ==--34b10a5eca9026f8cc41bbd71c4d684abbe607bf/file2.extension"
      }
  EOS
  def show
    # This file_push may have expired since the last view.  Validate the file_push
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
      name = "#{@push.url_token}-f"

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
    @blur_css_class = Settings.files.enable_blur ? "spoiler" : ""

    render json: @push.to_json(payload: true)

    # We can't expire in this case because the attached files would be deleted and
    # downloading wouldn't work.
    # TODO: ActiveJob delete in 15 minutes after last view is shown.
    # # Expire if this is the last view for this push
    # @push.expire if !@push.views_remaining.positive?
  end

  private

  ##
  # log_view
  #
  # Record that a view is being made for a file_push
  #
  def log_view(file_push, manual_expiration: false)
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

    record[:successful] = file_push.expired ? false : true

    file_push.views.create(record)
    file_push
  end

  # Since determining this value between and HTML forms and JSON API requests can be a bit
  # tricky, we break this out to it's own function.
  def create_detect_retrieval_step(file_push, params)
    if Settings.files.enable_retrieval_step == true
      if params.key?(:retrieval_step)
        # User form data or json API request: :deletable_by_viewer can
        # be 'on', 'true', 'checked' or 'yes' to indicate a positive
        user_rs = params[:retrieval_step].to_s.downcase
        file_push.retrieval_step = %w[on yes checked true].include?(user_rs)
      else
        file_push.retrieval_step = if request.format.html?
          # HTML Form Checkboxes: when NOT checked the form attribute isn't submitted
          # at all so we set false - NOT deletable by viewers
          false
        else
          # The JSON API is implicit so if it's not specified, use the app
          # configured default
          Settings.files.retrieval_step_default
        end
      end
    else
      # RETRIEVAL_STEP_ENABLED not enabled
      file_push.retrieval_step = false
    end
  end

  # Since determining this value between and HTML forms and JSON API requests can be a bit
  # tricky, we break this out to it's own function.
  def create_detect_deletable_by_viewer(file_push, params)
    if Settings.files.enable_deletable_pushes == true
      if params.key?(:deletable_by_viewer)
        # User form data or json API request: :deletable_by_viewer can
        # be 'on', 'true', 'checked' or 'yes' to indicate a positive
        user_dvb = params[:deletable_by_viewer].to_s.downcase
        file_push.deletable_by_viewer = %w[on yes checked true].include?(user_dvb)
      else
        file_push.deletable_by_viewer = if request.format.html?
          # HTML Form Checkboxes: when NOT checked the form attribute isn't submitted
          # at all so we set false - NOT deletable by viewers
          false
        else
          # The JSON API is implicit so if it's not specified, use the app
          # configured default
          Settings.files.deletable_pushes_default
        end
      end
    else
      # DELETABLE_PASSWORDS_ENABLED not enabled
      file_push.deletable_by_viewer = false
    end
  end

  def set_push
    @push = FilePush.includes(:views).find_by!(url_token: params[:id])
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
      format.html { render template: "file_pushes/show_expired", layout: "naked" }
      format.json { render json: {error: "not-found"}.to_json, status: :not_found }
      format.any { head :not_acceptable }
    end
  end

  def file_push_params
    params.require(:file_push).permit(:payload, :expire_after_days, :expire_after_views,
      :retrieval_step, :deletable_by_viewer, :name, :note, :passphrase, files: [])
  end

  def print_preview_params
    params.permit(:id, :locale, :message, :show_expiration, :show_id)
  end
end
