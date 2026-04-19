# frozen_string_literal: true

class PushCreatedMailer < ApplicationMailer
  helper PushesHelper
  include Rails.application.routes.url_helpers
  include ApplicationHelper

  def notify
    return unless params[:record].present?

    @push = params[:record]
    locale = params[:locale]
    I18n.with_locale(locale || I18n.default_locale) do
      @secret_url = secret_url(@push, with_retrieval_step: @push.retrieval_step, locale: locale)
      @subject = "#{@push.user&.email.presence} #{_("has sent you a push")}"
      mail(
        to: params[:recipient],
        subject: @subject
      )
    end
  end
end
