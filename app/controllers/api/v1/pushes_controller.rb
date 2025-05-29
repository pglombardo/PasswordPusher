# frozen_string_literal: true

class Api::V1::PushesController < Api::BaseController
  include SetPushAttributes
  include LogEvents

  before_action :set_current_kind, only: [:create, :active, :expired]
  before_action :set_push, only: %i[show preview audit destroy]

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
        log_failed_passphrase(@push)

        # Passphrase hasn't been provided or is incorrect
        # Passphrase hasn't been provided or is incorrect
        render json: {error: t("pushes.passphrase_incorrect")}
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

  def preview
    @secret_url = helpers.secret_url(@push)
    render json: {url: @secret_url}, status: :ok
  end

  def audit
    if @push.user_id != current_user.id
      render json: {error: t("pushes.not_owner_push")}
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

  def destroy
    # Check if the push is deletable by the viewer or if the user is the owner
    unless @push.deletable_by_viewer || (@push.user == current_user)
      render json: {error: t("pushes.not_deletable_or_not_owner")}, status: :unprocessable_entity
      return
    end

    if @push.expired
      render json: {error: t("pushes.expire.already_expired")}, status: :unprocessable_entity
      return
    end

    if @push.expire
      log_expire(@push)
      render json: @push, status: :ok
    else
      render json: @push.errors, status: :unprocessable_entity
    end
  end

  def active
    unless Settings.enable_logins
      render json: {error: t("pushes.need_login_for_active")}, status: :unauthorized
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

  def expired
    unless Settings.enable_logins
      render json: {error: t("pushes.need_login_for_expired")}, status: :unauthorized
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
    @current_kind = if request.path.start_with?("/f") || params.key?(:file_push)
      "file"
    elsif request.path.start_with?("/r") || params.key?(:url)
      "url"
    else
      "text"
    end
  end
end
