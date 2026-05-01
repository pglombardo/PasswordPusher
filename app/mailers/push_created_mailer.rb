# frozen_string_literal: true

class PushCreatedMailer < ApplicationMailer
  helper PushesHelper
  include Rails.application.routes.url_helpers
  include ApplicationHelper

  def notify
    @push = params[:push]
    locale = permitted_locale?(params[:locale]) ? params[:locale] : I18n.default_locale

    I18n.with_locale(locale || I18n.default_locale) do
      @secret_url = mailer_secret_push_url(@push, params[:locale])
      @subject = "#{@push.user&.email.presence} #{_("has sent you a push")}"
      mail(
        to: params[:recipient],
        subject: @subject
      )
    end
  end

  private

  def mailer_secret_push_url(push, selected_locale)
    raw_url = if push.retrieval_step
      Settings.override_base_url ? Settings.override_base_url + preliminary_push_path(push) : preliminary_push_url(push)
    else
      Settings.override_base_url ? Settings.override_base_url + push_path(push) : push_url(push)
    end

    # Delete any existing ?locale= query parameter
    raw_url = raw_url.split("?").first

    if permitted_locale?(selected_locale)
      # Append the locale query parameter
      raw_url += "?locale=#{selected_locale}"
    end

    # Support forced https links with FORCE_SSL env var
    raw_url = raw_url.gsub(/http/i, "https") if ENV.key?("FORCE_SSL")

    raw_url
  end

  def permitted_locale?(locale)
    I18n.config.available_locales_set.include?(locale)
  end
end
