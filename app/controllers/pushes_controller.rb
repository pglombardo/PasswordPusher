# frozen_string_literal: true

require "securerandom"

class PushesController < BaseController
  include SetPushAttributes
  include LogEvents
  
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
    
    @push.user_id = current_user.id if user_signed_in?

    create_detect_deletable_by_viewer(@push, push_params)
    create_detect_retrieval_step(@push, push_params)

    if @push.save
      log_creation(@push)
      
      redirect_to preview_push_path(@push)
    else
      if @push.kind == "text"
        @text_tab = true
      elsif @push.kind == "files"
        @files_tab = true
      elsif @push.kind == "url"
        @url_tab = true
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

    @push.expire!
    log_expire(@push)

    respond_to do |format|
      format.html { redirect_to @push, notice: t("pushes.expire.expired") }
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
    @push.check_limits

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
    @push.check_limits

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

    # If files are attached, we can't expire immediately as the viewer still needs
    # to download the files.  In the case of files, this push will be expired on the
    # next ExpirePushesJob run or next view attempt.  Whichever comes first.
    if !@push.files.attached? && !@push.views_remaining.positive?
      # Expire if this is the last view for this push
      @push.expire!
    end
    
    if @push.kind == "url"
      # Redirect to the URL
      redirect_to @push.payload, allow_other_host: true, status: :see_other
    else
      render layout: "bare"
    end
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
      format.html { render template: "pushes/show_expired", layout: "naked" }
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
