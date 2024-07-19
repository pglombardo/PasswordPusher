module SetLocale
  extend ActiveSupport::Concern

  included do
    around_action :set_locale
  end

  def set_locale(&action)
    I18n.with_locale(find_locale, &action)
  end

  private

  def find_locale
    locale_from_params || locale_from_user || locale_from_header || I18n.default_locale
  end

  def valid_locale?(locale)
    I18n.config.available_locales_set.include?(locale) ? locale : nil
  end

  def locale_from_params
    valid_locale?(params[:locale])
  end

  def locale_from_user
    return unless user_signed_in?
    valid_locale?(current_user.preferred_language)
  end

  def locale_from_header
    locale = request.env.fetch("HTTP_ACCEPT_LANGUAGE", "").scan(/^[a-z]{2}(?:-[a-zA-Z]{2})?/).first
    valid_locale?(locale) || valid_locale?(locale&.split("-")&.first)
  end
end
