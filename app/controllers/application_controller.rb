# frozen_string_literal: true

class ApplicationController < ActionController::Base
  protect_from_forgery unless: -> { request.format.json? }
  around_action :custom_set_locale_from_url

  add_flash_types :info, :error, :success, :warning

  def custom_set_locale_from_url
    locale_from_url = RouteTranslator.locale_from_params(params) ||
      RouteTranslator::Host.locale_from_host(request.host) ||
      I18n.default_locale
    if locale_from_url
      old_locale = I18n.locale
      I18n.locale = locale_from_url
    end

    yield
  ensure
    I18n.locale = old_locale if locale_from_url
  end

  def not_found
    raise ActionController::RoutingError, _("Not Found")
  end

  private

  def render_error(status, _exception)
    respond_to do |format|
      format.html { render template: "errors/error_#{status}", layout: "layouts/application", status: }
      format.all { render nothing: true, status: }
    end
  end
end
