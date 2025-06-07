# frozen_string_literal: true

class PushesController < BaseController
  include SetPushAttributes
  include LogEvents

  before_action :set_push, except: %i[new create index]
  before_action :check_allowed

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
    if @push.passphrase.present?
      # Construct the passphrase cookie name
      name = "#{@push.url_token}-p"

      # The passphrase can be passed in the params or in the cookie (default)
      # JSON requests must pass the passphrase in the params
      has_passphrase = cookies[name] == @push.passphrase_ciphertext

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
    @blur_css_class = @push.settings_for_kind.enable_blur ? "spoiler" : ""

    if @push.kind == "url"
      # Redirect to the URL
      redirect_to @push.payload, allow_other_host: true, status: :see_other
    else
      render layout: "bare"
    end

    # If files are attached, we can't expire immediately as the viewer still needs
    # to download the files.  In the case of files, this push will be expired on the
    # next ExpirePushesJob run or next view attempt.  Whichever comes first.
    if !@push.files.attached? && !@push.views_remaining.positive?
      # Expire if this is the last view for this push
      @push.expire!
    end
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
      flash[:alert] = t("pushes.access.incorrect")
      redirect_to passphrase_push_path(@push.url_token)
    end
  end

  # GET /passwords/new
  def new
    @push = Push.new

    set_kind_by_tab

    # MIGRATION - ask
    # Special fix for: https://github.com/pglombardo/PasswordPusher/issues/2811
    @push.passphrase = ""
  end

  def create
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
      elsif @push.kind == "file"
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

  def audit
    if @push.user_id != current_user.id
      redirect_to :root, notice: t("pushes.not_owner_push")
      return
    end

    @secret_url = helpers.secret_url(@push)
  end

  def expire
    # Check if the push is deletable by the viewer or if the user is the owner
    unless @push.deletable_by_viewer || (@push.user == current_user)
      redirect_to :root, notice: t("pushes.not_deletable_or_not_owner")
      return
    end

    if @push.expired
      redirect_to @push, notice: t("pushes.expire.already_expired")
      return
    end

    @push.expire!
    log_expire(@push)

    respond_to do |format|
      format.html { redirect_to @push, notice: t("pushes.expire.expired") }
    end
  end

  def index
    @filter = params[:filter]

    @pushes = if @filter
      Push.includes(:audit_logs)
        .where(user_id: current_user.id, expired: @filter == "expired")
        .page(params[:page])
        .order(created_at: :desc)
    else
      Push.includes(:audit_logs)
        .where(user_id: current_user.id)
        .page(params[:page])
        .order(created_at: :desc)
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
    case params.dig(:push, :kind)
    when "url"
      params.require(:push).permit(:kind, :name, :expire_after_days, :expire_after_views,
        :retrieval_step, :payload, :note, :passphrase)
    when "file"
      params.require(:push).permit(:kind, :name, :expire_after_days, :expire_after_views, :deletable_by_viewer,
        :retrieval_step, :payload, :note, :passphrase, files: [])
    else
      params.require(:push).permit(:kind, :name, :expire_after_days, :expire_after_views, :deletable_by_viewer,
        :retrieval_step, :payload, :note, :passphrase)
    end
  rescue => e
    Rails.logger.error("Error in push_params: #{e.message}")
    raise e
  end

  def print_preview_params
    params.permit(:id, :locale, :message, :show_expiration, :show_id)
  end

  def set_kind_by_tab
    # Track which tab to show
    if params.key?("tab")
      if params["tab"] == "text"
        @push.kind = "text"
        @text_tab = true
      elsif params["tab"] == "files"
        @push.kind = "file"
        @files_tab = true
      elsif params["tab"] == "url"
        @push.kind = "url"
        @url_tab = true
      elsif params["tab"] == "qr"
        @push.kind = "qr"
        @qr_tab = true
      else
        @push.kind = "text"
        @text_tab = true
      end
    else
      @push.kind = "text"
      @text_tab = true
    end
  end

  def check_allowed
    if action_name == "index"
      if Settings.enable_logins
        authenticate_user!
      else
        redirect_to :root
        return
      end
    end

    @push_kind = if %w[preview print_preview preliminary passphrase access show expire audit].include?(action_name)
      @push.kind
    elsif action_name == "new"
      case params["tab"]
      when "files"
        "file"
      when "url"
        "url"
      when "qr"
        "qr"
      else
        "text"
      end
    elsif action_name == "create"
      push_params.dig(:push, :kind) || "text"
    end

    case @push_kind
    when "file"
      # File pushes only enabled when logins are enabled.

      if Settings.enable_logins && Settings.enable_file_pushes
        unless %w[preliminary passphrase access show expire].include?(action_name)
          authenticate_user!
        end
      else
        redirect_to root_path, notice: t("pushes.file_pushes_disabled")
      end

    when "url"
      # URL pushes only enabled when logins are enabled.
      if Settings.enable_logins && Settings.enable_url_pushes
        unless %w[preliminary passphrase access show expire].include?(action_name)
          authenticate_user!
        end
      else
        redirect_to root_path, notice: t("pushes.url_pushes_disabled")
      end

    when "qr"
      # QR code pushes only enabled when logins are enabled.
      if Settings.enable_logins && Settings.enable_qr_pushes
        unless %w[preliminary passphrase access show expire].include?(action_name)
          authenticate_user!
        end
      else
        redirect_to root_path, notice: t("pushes.qr_pushes_disabled")
      end
    when "text"
      unless %w[new create preview print_preview preliminary passphrase access show expire].include?(action_name)
        authenticate_user!
      end

      if %w[new create].include?(action_name) && Settings.enable_logins && !Settings.allow_anonymous
        # Require authentication if allow_anonymous is false
        # See config/settings.yml
        authenticate_user!
      end
    end
  end
end
