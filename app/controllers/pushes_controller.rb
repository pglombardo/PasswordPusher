# frozen_string_literal: true

require "securerandom"

class PushesController < BaseController
  before_action :set_push, except: %i[new create index]

  # Authentication always except for these actions
  before_action :authenticate_user!, except: %i[new create preview print_preview preliminary passphrase access show expire]
  before_action :set_active_tab, only: %i[new]

 
  # POST /p/:url_token/access
  def access
    # Construct the passphrase cookie name
    name = "#{@push.url_token}-p"

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
      redirect_to push_path(@push.url_token)
    else
      # Passphrase is invalid
      log_failed_passphrase(@push)

      # Redirect to the passphrase page
      flash[:alert] =
        _("That passphrase is incorrect.  Please try again or contact the person or organization that sent you this link.")
      redirect_to passphrase_push_path(@push.url_token)
    end
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

    @push = Push.new(push_params)
    

    if @push.file? && push_params.key?(:files) &&
        push_params[:files].count { |e| e != "" } > settings_for(@push).max_file_uploads
      msg = t("pushes.form.upload_limit", count: settings_for(@push).max_file_uploads)
      flash.now[:alert] = msg
      render :new, status: :unprocessable_entity
      return
    end
    
    if @push.text? 
      
      # params[:push] has to exist
      # params[:push] has to be a ActionController::Parameters (Hash)
      text_param = params.fetch(:push, {})
      unless text_param.respond_to?(:fetch)
        redirect_to new_push_path(locale: locale.to_s), status: :unprocessable_entity, notice: "Bad Request"
        return
      end

      # params[:push][:payload] || params[:password][:payload] has to exist
      # params[:push][:payload] can't be blank
      # params[:push][:payload] must have a length between 1 and 1 megabyte
      payload_param = text_param.fetch(:payload, "")
      unless payload_param.is_a?(String) && payload_param.length.between?(1, 1.megabyte)
        redirect_to root_path(locale: locale.to_s), status: :unprocessable_entity, notice: "Bad Request"
        return
      end
    end
    
    @push.expire_after_days ||= settings_for(@push).expire_after_days_default
    @push.expire_after_views ||= settings_for(@push).expire_after_views_default
    @push.user_id = current_user.id if user_signed_in?
    @push.url_token = SecureRandom.urlsafe_base64(rand(8..14)).downcase

    create_detect_deletable_by_viewer(@push, params)
    create_detect_retrieval_step(@push, params)

    @push.note = push_params.fetch(:note, "")
    @push.passphrase = push_params.fetch(:passphrase, "")

    @push.validate!

    user_id = current_user.id if user_signed_in?
    @push.audit_logs.build(kind: :creation, user_id:, ip: request.remote_ip,
      user_agent: request.env["HTTP_USER_AGENT"], referrer: request.env["HTTP_REFERER"])

    if @push.errors.empty? && @push.save
      redirect_to preview_push_path(@push)
    else
      if @push.kind == "text"
        @text_tab = true
      elsif @push.kind == "files"
        @files_tab = true
      elsif @push.kind == "url"
        @url_tab = true
      elsif @push.kind == "qr"
        @qr_tab = true
      else
        @text_tab = true
      end
      render action: "new", status: :unprocessable_entity
    end
  end

  def expire
    # Check if the push is deletable by the viewer or if the user is the owner
    if @push.deletable_by_viewer == false && @push.user_id != current_user&.id
      redirect_to :root, notice: _("That push is not deletable by viewers and does not belong to you.")
      return
    end

    if @push.expired
      redirect_to @push, notice: _("That push is already expired.")
      return
    end

    log_expire(@push)

    @push.expired = true
    @push.payload = nil
    @push.deleted = true
    if @push.file?
      @push.files.purge
    end
    @push.expired_on = Time.zone.now

    if @push.save
      redirect_to @push, notice: _("The push content has been deleted and the secret URL expired.")
    else
      render action: "new", status: :unprocessable_entity
    end
  end

  def index
    unless Settings.enable_logins
      redirect_to :root
      return
    end

    @filter = params[:filter]


    if @filter
      @pushes = Push.includes(:audit_logs)
        .where(user_id: current_user.id, expired: @filter == "expired")
        .page(params[:page])
        .order(created_at: :desc)
    else
      @pushes = Push.includes(:audit_logs)
        .where(user_id: current_user.id)
        .page(params[:page])
        .order(created_at: :desc)
    end
  end

  # GET /passwords/new
  def new
    @push = Push.new

    if params.key?("tab")
      if params["tab"] == "text"
        @push.kind = "text"
      elsif params["tab"] == "files"
        @push.kind = "file"
      elsif params["tab"] == "url"
        @push.kind = "url"
      else
        @push.kind = "text"
      end
    else
      @push.kind = "text"
    end
    
    # MIGRATION - ask
    # Special fix for: https://github.com/pglombardo/PasswordPusher/issues/2811
    @push.passphrase = ""

    respond_to(&:html)
  end

  # GET /p/:url_token/passphrase
  def passphrase
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
      render template: "pushes/show_expired", layout: "naked"
      return
    else
      @secret_url = helpers.secret_url(@push, with_retrieval_step: false, locale: params[:locale])
    end

    render action: "preliminary", layout: "naked"
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

    render action: "print_preview", layout: "naked"
  end


  def show
    # This push may have expired since the last view.  Validate the push
    # expiration before doing anything.
    @push.validate!

    if @push.expired
      log_view(@push)
      render template: "pushes/show_expired", layout: "naked"
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
        redirect_to passphrase_push_path(@push.url_token)
        return
      end

      # Delete the cookie
      cookies.delete name
    end

    log_view(@push)
    expires_now

    # Optionally blur the text payload
    @blur_css_class = settings_for(@push).enable_blur ? "spoiler" : ""

    render layout: "bare"

    # Expire if this is the last view for this push
    if @push.text?
      @push.expire unless @push.views_remaining.positive?
    end
  end


  private

  ##
  # log_view
  #
  # Record that a view is being made for a push
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

  # Since determining this value between and HTML forms and JSON API requests can be a bit
  # tricky, we break this out to it's own function.
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
      format.html { render template: "pushes/show_expired", layout: "naked" }
      format.json { render json: {error: "not-found"}.to_json, status: :not_found }
      format.any { head :not_acceptable }
    end
  end

  def push_params
    params.require(:push).permit(:kind, :payload, :expire_after_days, :expire_after_views,
      :retrieval_step, :deletable_by_viewer, :name, :note, :passphrase, files: [])
  end

  def print_preview_params
    params.permit(:id, :locale, :message, :show_expiration, :show_id)
  end

  def set_active_tab
    # Track which tab to show
    if params.key?("tab")
      if params["tab"] == "text"
        @text_tab = true
      elsif params["tab"] == "files"
        @files_tab = true
      elsif params["tab"] == "url"
        @url_tab = true
      else
        @text_tab = true
      end
    else
      @text_tab = true
    end
  end
end
