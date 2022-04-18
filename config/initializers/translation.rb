# Permitted locales available for the application
I18n.available_locales = %i[ca cs da de en es fr hu it nl no pl pt-BR sr sv]

# Ability to set default locale to something other than :en
# See config/settings.yml
I18n.default_locale = Settings.default_locale

TranslationIO.configure do |config|
  config.api_key        = 'cc6a66a15e02433aa9d0afeb39835b8c'
  config.source_locale  = 'en'
  config.target_locales = %i[ca cs da de es fr hu it nl no pl pt-BR sr sv]

  # Uncomment this if you don't want to use gettext
  # config.disable_gettext = true

  # Uncomment this if you already use gettext or fast_gettext
  # config.locales_path = File.join('path', 'to', 'gettext_locale')

  # Find other useful usage information here:
  # https://github.com/translation/rails#readme
end

