# frozen_string_literal: true

class Api::V2::PushesController < Api::V1::PushesController
  before_action :force_json_format

  before_action :set_push, only: %i[show preview audit destroy notify_by_email]

  def notify_by_email
    set_notify_by_email(@push, notify_by_email_params, required: true)

    if @push.valid?
      log_creation_email_send(@push)
      render json: {}, status: :created
    else
      render json: @push.errors, status: :unprocessable_entity
    end
  end

  private

  def force_json_format
    request.format = :json
  end

  def set_notify_by_email(push, permitted_params, required: false)
    push.notify_by_email_recipients = permitted_params[:recipients]
    push.notify_by_email_locale = permitted_params[:locale]
    push.notify_by_email_creator = current_user if user_signed_in?
    push.notify_by_email_required = required
  end

  def notify_by_email_params
    params.permit(:recipients, :locale)
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
end
