# frozen_string_literal: true

class Api::V2::PushesController < Api::V1::PushesController
  before_action :force_json_format

  before_action :set_push, only: %i[show preview audit destroy notify_by_email]
  before_action :check_notify_by_email, only: %i[create]

  def notify_by_email
    @push.notify_by_email_recipients = params[:recipients]
    @push.notify_by_email_locale = params[:locale]
    @push.notify_by_email_required = true

    if @push.valid?
      log_creation_email_send(@push)
      render json: {}, status: :ok
    else
      render json: @push.errors, status: :unprocessable_entity
    end
  end

  private

  def force_json_format
    request.format = :json
  end

  def push_params
    permitted = params.require(:push).permit(:name, :kind, :expire_after_days, :expire_after_views,
      :deletable_by_viewer, :retrieval_step, :payload, :note, :passphrase, :notify_by_email_recipients, :notify_by_email_locale, files: [])

    # For v2 requests, file uploads imply a file push unless kind is explicit.
    if permitted[:kind].blank? && permitted[:files].present?
      permitted[:kind] = "file"
    end

    permitted
  rescue => e
    Rails.logger.error("Error in push_params: #{e.message}")
    raise e
  end

  def check_notify_by_email
    if params.dig(:push, :notify_by_email_recipients).present?
      if Settings.disable_logins || Settings.mail.smtp_address.blank?
        render json: {error: "Notifying by email is not available."}, status: :unprocessable_entity
        nil
      elsif !user_signed_in?
        render json: {error: I18n._("Notifying by email is only available when signed in.")}, status: :unauthorized
        nil
      end
    end
  end
end
