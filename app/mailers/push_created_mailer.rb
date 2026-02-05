# frozen_string_literal: true

class PushCreatedMailer < ApplicationMailer
  helper PushesHelper
  include Rails.application.routes.url_helpers
  include ApplicationHelper
  include PushesHelper

  def notify
    @push = params[:record]
    locale = @push.notify_emails_to_locale.presence
    I18n.with_locale(locale || I18n.default_locale) do
      @secret_url = secret_url(@push, with_retrieval_step: @push.retrieval_step, locale: locale)
      @subject = "#{@push.user&.email.presence || _("Someone")} #{_("has sent you a Push")}"
      # Full duration for email body (e.g. "7 day(s), 0 hour(s) and 0 minute(s)")
      @duration_text = format_minutes_duration(@push.expire_after_days.to_i * 24 * 60)
      mail(
        to: Pwpush::NotifyEmailsTo.parse_emails(@push.notify_emails_to),
        subject: @subject
      )
    end
  end
end
