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
      mail(
        to: Pwpush::NotifyEmailsTo.parse_emails(@push.notify_emails_to),
        subject: @subject
      )
    end
  end
end
