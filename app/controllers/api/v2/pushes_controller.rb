# frozen_string_literal: true

class Api::V2::PushesController < Api::V1::PushesController
  before_action :force_json_format

  before_action :set_push, only: %i[show preview audit destroy notify_by_email]

  def notify_by_email
    authenticate_user!

    if @push.user != current_user
      render json: {error: "That push doesn't belong to you."}, status: :forbidden
      return
    end

    assign_notify_by_email_params(@push, notify_by_email_params, required: true)

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
