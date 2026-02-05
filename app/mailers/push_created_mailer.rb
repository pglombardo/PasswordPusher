# frozen_string_literal: true

class PushCreatedMailer < ApplicationMailer
  include PushesHelper

  def notify
    @push = params[:record]
    locale = @push.notify_emails_to_locale.presence
    I18n.with_locale(locale || I18n.default_locale) do
      @secret_url = secret_url_for_push(@push, locale: locale)
      @subject = "#{@push.user&.email.presence || _("Someone")} #{_("has sent you a Push")}"
      # Full duration for email body (e.g. "7 day(s), 0 hour(s) and 0 minute(s)")
      @duration_text = format_minutes_duration(@push.expire_after_days.to_i * 24 * 60)
      mail(
        to: Pwpush::NotifyEmailsTo.parse_emails(@push.notify_emails_to),
        subject: @subject
      )
    end
  end

  private

  def secret_url_for_push(push, locale: nil)
    raw_url = if push.retrieval_step
      preliminary_push_url(push)
    else
      push_url(push)
    end
    base = raw_url.split("?").first
    if locale.present? && Array(Settings.enabled_language_codes).include?(locale.to_s)
      base += "?locale=#{locale}"
    end
    base = base.gsub(/http/i, "https") if ENV.key?("FORCE_SSL")
    base
  end
end
