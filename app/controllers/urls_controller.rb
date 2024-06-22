# frozen_string_literal: true

require "securerandom"

class UrlsController < BaseController
  helper UrlsHelper

  # Authentication always except for the following:
  acts_as_token_authentication_handler_for User, except: %i[show new preliminary passphrase access]

  before_action :set_push, only: %i[show passphrase access preview print_preview preliminary audit destroy]

  resource_description do
    name "URL Pushes"
    short "Interact directly with URL pushes.  This feature (and corresponding API) is currently in beta."
  end

  api :GET, "/r/:url_token.json", "Retrieve a URL push."
  param :url_token, String, desc: "Secret URL token of a previously created push.", required: true
  formats ["json"]
  example 'curl -X GET -H "X-User-Email: <email>" -H "X-User-Token: MyAPIToken" https://pwpush.com/r/fk27vnslkd.json'
  description "Retrieves a push including it's payload and details.  If the push is still active, " \
              "this will burn a view and the transaction will be logged in the push audit log.  If the push " \
              "has a passphrase, provide it in a ?passphrase=xxx GET parameter."
  def show
    # This url may have expired since the last view.  Validate the url
    # expiration before doing anything.
    @push.validate!

    if @push.expired
      log_view(@push)
      respond_to do |format|
        format.html { render template: "urls/show_expired", layout: "naked" }
        format.json { render json: @push.to_json(payload: true) }
      end
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
        respond_to do |format|
          format.html { redirect_to passphrase_url_path(@push.url_token) }
          format.json { render json: {error: "This push has a passphrase that was incorrect or not provided."} }
        end
        return
      end

      # Delete the cookie
      cookies.delete name
    end

    log_view(@push)
    expires_now

    respond_to do |format|
      format.html { redirect_to @push.payload, allow_other_host: true, status: :see_other }
      format.json { render json: @push.to_json(payload: true) }
    end

    @push.expire unless @push.views_remaining.positive?
  end

  # GET /r/:url_token/passphrase
  def passphrase
    if @push.expired
      respond_to do |format|
        format.html { render template: "urls/show_expired", layout: "naked" }
      end
      return
    end

    respond_to do |format|
      format.html { render action: "passphrase", layout: "naked" }
    end
  end

  # POST /r/:url_token/access
  def access
    # Construct the passphrase cookie name
    name = "#{@push.url_token}-r"

    # Validate the passphrase
    if @push.passphrase == params[:passphrase]
      # Passphrase is valid
      # Set the passphrase cookie
      cookies[name] = {value: @push.passphrase_ciphertext, expires: 10.minutes.from_now}
      # Redirect to the payload
      redirect_to url_path(@push.url_token)
    else
      # Passphrase is invalid
      # Redirect to the passphrase page
      flash[:alert] =
        _("That passphrase is incorrect.  Please try again or contact the person or organization that sent you this link.")
      redirect_to passphrase_url_path(@push.url_token)
    end
  end

  # GET /urls/new
  def new
    if user_signed_in?
      @push = Url.new

      respond_to(&:html)
    else
      respond_to do |format|
        format.html { render template: "urls/new_anonymous" }
      end
    end
  end

  api :POST, "/r.json", "Create a new URL push."
  param :url, Hash, "Push details", required: true do
    param :payload, String, desc: "The URL encoded URL to redirect to.", required: true
    param :passphrase, String, desc: "Require recipients to enter this passphrase to view the created push."
    param :note, String,
      desc: "If authenticated, the URL encoded note for this push.  Visible only to the push creator.", allow_blank: true
    param :expire_after_days, Integer, desc: "Expire secret link and delete after this many days."
    param :expire_after_views, Integer, desc: "Expire secret link and delete after this many views."
    param :retrieval_step, %w[true false], desc: "Helps to avoid chat systems and URL scanners from eating up views."
  end
  formats ["json"]
  example 'curl -X POST -H "X-User-Email: <email>" -H "X-User-Token: MyAPIToken" ' \
          '--data "url[payload]=myurl&url[expire_after_days]=2&url[expire_after_views]=10" https://pwpush.com/r.json'
  def create
    # Require authentication if allow_anonymous is false
    # See config/settings.yml
    authenticate_user! if Settings.enable_logins && !Settings.allow_anonymous

    begin
      @push = Url.new(url_params)
    rescue ActionController::ParameterMissing
      @push = Url.new
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: {error: "No URL or note provided."}, status: :unprocessable_entity }
      end
      return
    end

    url_param = params.fetch(:url, {})
    payload_param = url_param.fetch(:payload, "")

    unless helpers.valid_url?(payload_param)
      msg = _("Invalid URL: Must have a valid URI scheme.")
      respond_to do |format|
        format.html do
          flash.now[:error] = msg
          render :new, status: :unprocessable_entity
        end
        format.json { render json: {error: msg}, status: :unprocessable_entity }
      end
      return
    end

    @push.expire_after_days = params[:url].fetch(:expire_after_days, Settings.url.expire_after_days_default)
    @push.expire_after_views = params[:url].fetch(:expire_after_views, Settings.url.expire_after_views_default)
    @push.user_id = current_user.id if user_signed_in?
    @push.url_token = SecureRandom.urlsafe_base64(rand(8..14)).downcase

    create_detect_retrieval_step(@push, params)

    @push.payload = params[:url][:payload]
    @push.note = params[:url][:note] if params[:url].fetch(:note, "").present?
    @push.passphrase = params[:url].fetch(:passphrase, "")

    @push.validate!

    respond_to do |format|
      if @push.save
        format.html { redirect_to preview_url_path(@push) }
        format.json { render json: @push, status: :created }
      else
        format.html { render action: "new", status: :unprocessable_entity }
        format.json { render json: @push.errors, status: :unprocessable_entity }
      end
    end
  end

  api :GET, "/r/:url_token/preview.json", "Helper endpoint to retrieve the fully qualified secret URL of a push."
  param :url_token, String, desc: "Secret URL token of a previously created push.", required: true
  formats ["json"]
  example 'curl -X GET -H "X-User-Email: <email>" -H "X-User-Token: MyAPIToken" https://pwpush.com/r/fk27vnslkd/preview.json'
  description ""
  def preview
    @secret_url = helpers.secret_url(@push)
    @qr_code = helpers.qr_code(@secret_url)

    respond_to do |format|
      format.html { render action: "preview" }
      format.json { render json: {url: @secret_url}, status: :ok }
    end
  end

  def print_preview
    @secret_url = helpers.secret_url(@push)
    @qr_code = helpers.qr_code(@secret_url)

    @message = print_preview_params[:message]
    @show_expiration = print_preview_params[:show_expiration]
    @show_id = print_preview_params[:show_id]

    respond_to do |format|
      format.html { render action: "print_preview", layout: "naked" }
      format.json { render json: {url: @secret_url}, status: :ok }
    end
  end

  def preliminary
    # This password may have expired since the last view.  Validate the password
    # expiration before doing anything.
    @push.validate!

    if @push.expired
      log_view(@push)
      respond_to do |format|
        format.html { render template: "urls/show_expired", layout: "naked" }
        format.json { render json: @push.to_json(payload: true) }
      end
      return
    else
      @secret_url = helpers.raw_secret_url(@push)
    end

    respond_to do |format|
      format.html { render action: "preliminary", layout: "naked" }
    end
  end

  api :GET, "/r/:url_token/audit.json", "Retrieve the audit log for a push."
  param :url_token, String, desc: "Secret URL token of a previously created push.", required: true
  formats ["json"]
  example 'curl -X GET -H "X-User-Email: <email>" -H "X-User-Token: MyAPIToken" https://pwpush.com/r/fk27vnslkd/audit.json'
  description "This will return array of views including IP, referrer and other such metadata.  The _successful_ " \
              "field indicates whether the view was made while the push was still active (and not expired).  " \
              "Note that you must be the owner of the push to retrieve " \
              "the audit log and this call will always return 401 Unauthorized for pushes not owned by the " \
              "credentials provided."
  def audit
    if @push.user_id != current_user.id
      respond_to do |format|
        format.html { redirect_to :root, notice: _("That push doesn't belong to you.") }
        format.json { render json: {error: "That push doesn't belong to you."} }
      end
      return
    end

    @secret_url = helpers.secret_url(@push)

    respond_to do |format|
      format.html {}
      format.json do
        render json: {views: @push.views}.to_json(except: %i[user_id url_id id])
      end
    end
  end

  api :DELETE, "/r/:url_token.json", "Expire a push: delete the payload and expire the secret URL."
  param :url_token, String, desc: "Secret URL token of a previously created push.", required: true
  formats ["json"]
  example 'curl -X DELETE -H "X-User-Email: <email>" -H "X-User-Token: MyAPIToken" https://pwpush.com/r/fkwjfvhall92.json'
  description "Expires a push immediately.  Must be authenticated & owner of the push _or_ the " \
              "push must have been created with _deleteable_by_viewer_."
  def destroy
    is_owner = false

    if user_signed_in?
      # Check if logged in user owns the url to be expired
      if @push.user_id == current_user.id
        is_owner = true
      else
        redirect_to :root, notice: _("That push does not belong to you.")
        return
      end
    else
      redirect_to :root, notice: _("That push does not belong to you.")
      return
    end

    if @push.expired
      respond_to do |format|
        format.html { redirect_to :root, notice: _("That push is already expired.") }
        format.json { render json: {error: _("That push is already expired.")}, status: :unprocessable_entity }
      end
      return
    end

    log_view(@push, manual_expiration: true)

    @push.expired = true
    @push.payload = nil
    @push.deleted = true
    @push.expired_on = Time.zone.now

    respond_to do |format|
      if @push.save
        format.html do
          if is_owner
            redirect_to audit_url_path(@push),
              notice: _("The push content has been deleted and the secret URL expired.")
          else
            redirect_to @push,
              notice: _("The push content has been deleted and the secret URL expired.")
          end
        end
        format.json { render json: @push, status: :ok }
      else
        format.html { render action: "new", status: :unprocessable_entity }
        format.json { render json: @push.errors, status: :unprocessable_entity }
      end
    end
  end

  api :GET, "/r/active.json", "Retrieve your active URL pushes."
  formats ["json"]
  example 'curl -X GET -H "X-User-Email: <email>" -H "X-User-Token: MyAPIToken" https://pwpush.com/r/active.json'
  description "Returns the list of URL pushes that you previously pushed which are still active."
  def active
    unless Settings.enable_logins
      redirect_to :root
      return
    end

    @pushes = Url.includes(:views)
      .where(user_id: current_user.id, expired: false)
      .page(params[:page])
      .order(created_at: :desc)

    respond_to do |format|
      format.html {}
      format.json do
        json_parts = []
        @pushes.each do |push|
          json_parts << push.to_json(owner: true, payload: false)
        end
        render json: "[#{json_parts.join(",")}]"
      end
    end
  end

  api :GET, "/r/expired.json", "Retrieve your expired URL pushes."
  formats ["json"]
  example 'curl -X GET -H "X-User-Email: <email>" -H "X-User-Token: MyAPIToken" https://pwpush.com/r/expired.json'
  description "Returns the list of URL pushes that you previously pushed which have expired."
  def expired
    unless Settings.enable_logins
      redirect_to :root
      return
    end

    @pushes = Url.includes(:views)
      .where(user_id: current_user.id, expired: true)
      .page(params[:page])
      .order(created_at: :desc)

    respond_to do |format|
      format.html {}
      format.json do
        json_parts = []
        @pushes.each do |push|
          json_parts << push.to_json(owner: true, payload: false)
        end
        render json: "[#{json_parts.join(",")}]"
      end
    end
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
    respond_to do |format|
      format.html { render template: "urls/show_expired", layout: "naked" }
      format.json { render json: {error: "not-found"}.to_json, status: :not_found }
      format.any { head :not_acceptable }
    end
  end

  def url_params
    params.require(:url).permit(:payload, :expire_after_days, :expire_after_views, :retrieval_step, :note)
  end

  def print_preview_params
    params.permit(:id, :locale, :message, :show_expiration, :show_id)
  end
end
