# frozen_string_literal: true

class Api::V2::PushesController < Api::V1::PushesController
  before_action :force_json_format

  before_action :set_push, only: %i[show preview audit destroy notify_by_email]

  rate_limit to: 5, within: 1.minute, only: :notify_by_email,
    by: -> { current_user&.id },
    with: -> { render json: {error: I18n._("Too many email notification requests. Please try again in a minute.")}, status: :too_many_requests }

  # POST /api/v2/pushes.json
  #
  # v1's create is duplicated here so that v1 can stay untouched by the
  # notify_by_email feature. APIv1 is deprecated; the v1/v2 controllers
  # will be split out entirely in a follow-up PR.
  def create
    permitted_params = push_params

    authenticate_user! if requires_authentication_for_create?(permitted_params)

    permitted_notify_by_email_params = permitted_params.delete(:notify_by_email)

    @push = Push.new(permitted_params)

    if !permitted_params[:kind].present?
      @push.kind = if request.path.include?("/f.json")
        "file"
      elsif request.path.include?("/r.json")
        "url"
      elsif request.path.include?("/p.json") && permitted_params.key?(:files)
        "file"
      else
        "text"
      end
    end

    @push.user = current_user if user_signed_in?

    assign_deletable_by_viewer(@push, permitted_params)
    assign_retrieval_step(@push, permitted_params)

    if permitted_notify_by_email_params.present?
      assign_notify_by_email_params(@push, permitted_notify_by_email_params)
    end

    if @push.save
      log_creation(@push)
      log_creation_email_send(@push)

      render template: "pushes/show", status: :created
    else
      render json: @push.errors, status: :unprocessable_content
    end
  end

  def audit
    authenticate_user!

    if @push.user != current_user
      render json: {error: I18n._("That push doesn't belong to you.")}, status: :forbidden
      return
    end

    page = validate_page_parameter
    return if page.nil?

    @audit_logs = @push.audit_logs
      .order(created_at: :desc)
      .page(page)
      .per(50)

    @secret_url = helpers.secret_url(@push)
    render template: "pushes/audit", status: :ok
  end

  def notify_by_email
    authenticate_user!

    if @push.user != current_user
      render json: {error: I18n._("That push doesn't belong to you.")}, status: :forbidden
      return
    end

    permitted_notify_by_email_params = params.permit(:recipients, :locale)
    assign_notify_by_email_params(@push, permitted_notify_by_email_params, required: true)

    if @push.valid?
      log_creation_email_send(@push)
      render json: {message: I18n._("Recipient(s) are added to the queue to be sent.")}, status: :created
    else
      render json: @push.errors, status: :unprocessable_entity
    end
  end

  private

  def force_json_format
    request.format = :json
  end

  def set_push
    @push = if action_name == "audit"
      Push.includes(audit_logs: :notify_by_email).find_by!(url_token: params[:id])
    else
      Push.includes(:audit_logs).find_by!(url_token: params[:id])
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.json { render json: {error: "not-found"}.to_json, status: :not_found }
    end
  end

  def push_params
    permitted = params.require(:push).permit(:name, :kind, :expire_after_days, :expire_after_views,
      :deletable_by_viewer, :retrieval_step, :payload, :note, :passphrase, notify_by_email: [:recipients, :locale], files: [])

    # For v2 requests, file uploads imply a file push unless kind is explicit.
    if permitted[:kind].blank? && permitted[:files].present?
      permitted[:kind] = "file"
    end

    permitted
  rescue => e
    Rails.logger.error("Error in push_params: #{e.message}")
    raise e
  end

  def assign_notify_by_email_params(push, permitted_params, required: false)
    push.notify_by_email_recipients = permitted_params[:recipients]
    push.notify_by_email_locale = permitted_params[:locale]
    push.notify_by_email_creator = current_user if user_signed_in?
    push.notify_by_email_required = required
  end
end
