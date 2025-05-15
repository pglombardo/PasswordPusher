# frozen_string_literal: true

require "securerandom"

class UrlsController < BaseController
  helper UrlsHelper

  before_action :set_push, except: %i[new create active expired]

  # Authentication always except for these actions
  before_action :authenticate_user!, except: %i[preliminary passphrase access show destroy]

  # POST /r/:url_token/access
  def access
    # Construct the passphrase cookie name
    name = "#{@push.url_token}-r"

    # Validate the passphrase
    if @push.passphrase == params[:passphrase]
      # Passphrase is valid
      # Set the passphrase cookie
      cookies[name] = {
        value: @push.passphrase_ciphertext,
        expires: 3.minutes.from_now,
        httponly: true,                # Prevent JavaScript access to the cookie
        same_site: :strict             # Restrict the cookie to same-site requests
      }

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

  def active
    unless Settings.enable_logins
      redirect_to :root
      return
    end

    @pushes = Url.includes(:views)
      .where(user_id: current_user.id, expired: false)
      .page(params[:page])
      .order(created_at: :desc)
  end

  def audit
    if @push.user_id != current_user.id
      redirect_to :root, notice: _("That push doesn't belong to you.")
      return
    end

    @secret_url = helpers.secret_url(@push)
  end

  def create
    # Require authentication if allow_anonymous is false
    # See config/settings.yml
    authenticate_user! if Settings.enable_logins && !Settings.allow_anonymous

    begin
      @push = Url.new(url_params)
    rescue ActionController::ParameterMissing
      @push = Url.new
      render :new, status: :unprocessable_entity
      return
    end

    url_param = params.fetch(:url, {})
    payload_param = url_param.fetch(:payload, "")

    unless helpers.valid_url?(payload_param)
      msg = _("Invalid URL: Must have a valid URI scheme.")
      render :new, status: :unprocessable_entity, notice: msg
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
      redirect_to preview_url_path(@push)
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  def destroy
    # Check ownership
    if @push.user_id != current_user&.id
      redirect_to :root, notice: _("That push does not belong to you.")
      return
    end

    if @push.expired
      redirect_to @push
      return
    end

    log_view(@push, manual_expiration: true)

    @push.expired = true
    @push.payload = nil
    @push.deleted = true
    @push.expired_on = Time.zone.now

    if @push.save
      redirect_to @push, notice: _("The push content has been deleted and the secret URL expired.")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def expired
    unless Settings.enable_logins
      redirect_to :root
      return
    end

    @pushes = Url.includes(:views)
      .where(user_id: current_user.id, expired: true)
      .page(params[:page])
      .order(created_at: :desc)
  end

  # GET /urls/new
  def new
    @push = Url.new
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
  

  def preliminary
    # This password may have expired since the last view.  Validate the password
    # expiration before doing anything.
    @push.validate!

    if @push.expired
      log_view(@push)
      render template: "urls/show_expired", layout: "naked"
      return
    else
      @secret_url = helpers.secret_url(@push, with_retrieval_step: false, locale: params[:locale])
    end

    respond_to do |format|
      format.html { render action: "preliminary", layout: "naked" }
    end
  end


  def preview
    @secret_url = helpers.secret_url(@push)
    @qr_code = helpers.qr_code(@secret_url)
  end

  def print_preview
    @secret_url = helpers.secret_url(@push)
    @qr_code = helpers.qr_code(@secret_url)

    @message = print_preview_params[:message]
    @show_expiration = print_preview_params[:show_expiration]
    @show_id = print_preview_params[:show_id]

    render :print_preview, layout: "naked"
  end
  
  def show
    # This url may have expired since the last view.  Validate the url
    # expiration before doing anything.
    @push.validate!

    if @push.expired
      log_view(@push)
      render template: "urls/show_expired", layout: "naked"
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
        redirect_to passphrase_url_path(@push.url_token)
        return
      end

      # Delete the cookie
      cookies.delete name
    end

    log_view(@push)
    expires_now

    redirect_to @push.payload, allow_other_host: true, status: :see_other

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
    respond_to do |format|
      format.html { render template: "urls/show_expired", layout: "naked" }
      format.any { head :not_acceptable }
    end
  end

  def url_params
    params.require(:url).permit(:payload, :expire_after_days, :expire_after_views, :retrieval_step, :name, :note, :passphrase)
  end

  def print_preview_params
    params.permit(:id, :locale, :message, :show_expiration, :show_id)
  end
end
