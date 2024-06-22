# frozen_string_literal: true

require "securerandom"

class PasswordsController < BaseController
  # Use auth token (for JSON) if it's there but don't fall back to devise session
  acts_as_token_authentication_handler_for User, fallback: :none, only: %i[create destroy]

  # Audit & dashboard views (active & expired) always requires a login
  acts_as_token_authentication_handler_for User, only: %i[audit active expired]

  before_action :set_push, only: %i[show passphrase access preview print_preview preliminary audit destroy]

  resource_description do
    name "Text Pushes"
    short "Interact directly with text pushes."
  end

  api :GET, "/p/:url_token.json", "Retrieve a push."
  param :url_token, String, desc: "Secret URL token of a previously created push.", required: true
  formats ["json"]
  example 'curl -X GET -H "X-User-Email: <email>" -H "X-User-Token: MyAPIToken" https://pwpush.com/p/fk27vnslkd.json'
  description "Retrieves a push including it's payload and details.  If the push is still active, this " \
              "will burn a view and the transaction will be logged in the push audit log.  If the push " \
              "has a passphrase, provide it in a ?passphrase=xxx GET parameter."
  def show
    # This password may have expired since the last view.  Validate the password
    # expiration before doing anything.
    @push.validate!

    if @push.expired
      log_view(@push)
      respond_to do |format|
        format.html { render template: "passwords/show_expired", layout: "naked" }
        format.json { render json: @push.to_json(payload: true) }
      end
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
        respond_to do |format|
          format.html { redirect_to passphrase_password_path(@push.url_token) }
          format.json { render json: {error: "This push has a passphrase that was incorrect or not provided."} }
        end
        return
      end

      # Delete the cookie
      cookies.delete name
    end

    log_view(@push)
    expires_now

    # Optionally blur the text payload
    @blur_css_class = Settings.pw.enable_blur ? "spoiler" : ""

    respond_to do |format|
      format.html { render layout: "bare" }
      format.json { render json: @push.to_json(payload: true) }
    end

    # Expire if this is the last view for this push
    @push.expire unless @push.views_remaining.positive?
  end

  # GET /p/:url_token/passphrase
  def passphrase
    respond_to do |format|
      format.html { render action: "passphrase", layout: "naked" }
    end
  end

  # POST /p/:url_token/access
  def access
    # Construct the passphrase cookie name
    name = "#{@push.url_token}-p"

    # Validate the passphrase
    if @push.passphrase == params[:passphrase]
      # Passphrase is valid
      # Set the passphrase cookie
      cookies[name] = {value: @push.passphrase_ciphertext, expires: 10.minutes.from_now}
      # Redirect to the payload
      redirect_to password_path(@push.url_token)
    else
      # Passphrase is invalid
      # Redirect to the passphrase page
      flash[:alert] =
        _("That passphrase is incorrect.  Please try again or contact the person or organization that sent you this link.")
      redirect_to passphrase_password_path(@push.url_token)
    end
  end

  # GET /passwords/new
  def new
    # Require authentication if allow_anonymous is false
    # See config/settings.yml
    authenticate_user! if Settings.enable_logins && !Settings.allow_anonymous

    @push = Password.new

    respond_to(&:html)
  end

  api :POST, "/p.json", "Create a new push."
  param :password, Hash, "Push details", required: true do
    param :payload, String, desc: "The URL encoded password or secret text to share.", required: true
    param :passphrase, String, desc: "Require recipients to enter this passphrase to view the created push."
    param :note, String,
      desc: "If authenticated, the URL encoded note for this push.  Visible only to the push creator.", allow_blank: true
    param :expire_after_days, Integer, desc: "Expire secret link and delete after this many days."
    param :expire_after_views, Integer, desc: "Expire secret link and delete after this many views."
    param :deletable_by_viewer, %w[true false], desc: "Allow users to delete passwords once retrieved."
    param :retrieval_step, %w[true false], desc: "Helps to avoid chat systems and URL scanners from eating up views."
  end
  formats ["json"]
  example 'curl -X POST -H "X-User-Email: <email>" -H "X-User-Token: MyAPIToken" --data ' \
          '"password[payload]=mypassword&password[expire_after_days]=2&password[expire_after_views]=10" ' \
          "https://pwpush.com/p.json"
  def create
    # Require authentication if allow_anonymous is false
    # See config/settings.yml
    authenticate_user! if Settings.enable_logins && !Settings.allow_anonymous

    # params[:password] has to exist
    # params[:password] has to be a ActionController::Parameters (Hash)
    password_param = params.fetch(:password, {})
    unless password_param.respond_to?(:fetch)
      respond_to do |format|
        format.html { redirect_to root_path(locale: locale.to_s), status: :unprocessable_entity, notice: "Bad Request" }
        format.json { render json: {error: "No password, text or files provided."}, status: :unprocessable_entity }
      end
      return
    end

    # params[:password][:payload] || params[:password][:payload] has to exist
    # params[:password][:payload] can't be blank
    # params[:password][:payload] must have a length between 1 and 1 megabyte
    payload_param = password_param.fetch(:payload, "")
    unless payload_param.is_a?(String) && payload_param.length.between?(1, 1.megabyte)
      respond_to do |format|
        format.html { redirect_to root_path(locale: locale.to_s), status: :unprocessable_entity, notice: "Bad Request" }
        format.json do
          render json: {error: "Payload length must be between 1 and 1_048_576."}, status: :unprocessable_entity
        end
      end
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
    @push.note = params[:password].fetch(:note, "")
    @push.passphrase = params[:password].fetch(:passphrase, "")

    @push.validate!

    respond_to do |format|
      if @push.save
        format.html { redirect_to preview_password_path(@push) }
        format.json { render json: @push, status: :created }
      else
        format.html { render action: "new", status: :unprocessable_entity }
        format.json { render json: @push.errors, status: :unprocessable_entity }
      end
    end
  end

  api :GET, "/p/:url_token/preview.json", "Helper endpoint to retrieve the fully qualified secret URL of a push."
  param :url_token, String, desc: "Secret URL token of a previously created push.", required: true
  formats ["json"]
  example 'curl -X GET -H "X-User-Email: <email>" -H "X-User-Token: MyAPIToken" https://pwpush.com/p/fk27vnslkd/preview.json'
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
        format.html { render template: "passwords/show_expired", layout: "naked" }
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

  api :GET, "/p/:url_token/audit.json", "Retrieve the audit log for a push."
  param :url_token, String, desc: "Secret URL token of a previously created push.", required: true
  formats ["json"]
  example 'curl -X GET -H "X-User-Email: <email>" -H "X-User-Token: MyAPIToken" https://pwpush.com/p/fk27vnslkd/audit.json'
  description "This will return array of views including IP, referrer and other such metadata.  The " \
              "_successful_ field indicates whether the view was made while the push was still active " \
              "(and not expired).  Note that you must be the owner of the push to retrieve the audit log " \
              "and this call will always return 401 Unauthorized for pushes not owned by the credentials provided."
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
        render json: {views: @push.views}.to_json(except: %i[user_id password_id id])
      end
    end
  end

  api :DELETE, "/p/:url_token.json", "Expire a push: delete the payload and expire the secret URL."
  param :url_token, String, desc: "Secret URL token of a previously created push.", required: true
  formats ["json"]
  example 'curl -X DELETE -H "X-User-Email: <email>" -H "X-User-Token: MyAPIToken" https://pwpush.com/p/fkwjfvhall92.json'
  description "Expires a push immediately.  Must be authenticated & owner of the push _or_ the push must " \
              "have been created with _deleteable_by_viewer_."
  def destroy
    is_owner = false

    if user_signed_in?
      # Check if logged in user owns the password to be expired
      if @push.user_id == current_user.id
        is_owner = true
      else
        redirect_to :root, notice: _("That push does not belong to you.")
        return
      end
    elsif @push.deletable_by_viewer == false
      # Anonymous user - assure deletable_by_viewer enabled
      redirect_to :root, notice: _("That push is not deletable by viewers.")
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
            redirect_to audit_password_path(@push),
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

  api :GET, "/p/active.json", "Retrieve your active pushes."
  formats ["json"]
  example 'curl -X GET -H "X-User-Email: <email>" -H "X-User-Token: MyAPIToken" https://pwpush.com/p/active.json'
  description "Returns the list of password pushes that you previously pushed which are still active."
  def active
    unless Settings.enable_logins
      redirect_to :root
      return
    end

    @pushes = Password.includes(:views)
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

  api :GET, "/p/expired.json", "Retrieve your expired pushes."
  formats ["json"]
  example 'curl -X GET -H "X-User-Email: <email>" -H "X-User-Token: MyAPIToken" https://pwpush.com/p/expired.json'
  description "Returns the list of password pushes that you previously pushed which have expired."
  def expired
    unless Settings.enable_logins
      redirect_to :root
      return
    end

    @pushes = Password.includes(:views)
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
    @push = Password.includes(:views).find_by!(url_token: params[:id])
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
      format.html { render template: "passwords/show_expired", layout: "naked" }
      format.json { render json: {error: "not-found"}.to_json, status: :not_found }
      format.any { head :not_acceptable }
    end
  end

  def password_params
    params.require(:password).permit(:payload, :expire_after_days, :expire_after_views,
      :retrieval_step, :deletable_by_viewer, :note)
  end

  def print_preview_params
    params.permit(:id, :locale, :message, :show_expiration, :show_id)
  end
end
