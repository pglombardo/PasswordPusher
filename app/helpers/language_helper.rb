module LanguageHelper
  def language_options_for_select
    I18n.available_locales.map do |locale|
      [Settings.language_codes[locale], locale]
    end
  end
end
