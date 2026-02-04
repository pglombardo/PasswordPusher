# frozen_string_literal: true

class PushCreatedMailer < ApplicationMailer
  def notify
    @push = params[:record]
    locale = @push.notify_emails_to_locale.presence
    I18n.with_locale(locale || I18n.default_locale) do
      @secret_url = secret_url_for_push(@push, locale: locale)
      @subject = "#{@push.user&.email.presence || _("Someone")} #{_("has sent you a Push")}"
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
