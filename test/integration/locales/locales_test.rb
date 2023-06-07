require 'test_helper'

class LocalesTest < ActionDispatch::IntegrationTest
  def test_locales_exist
    for locale in I18n.available_locales
      get root_path, params: { locale: locale }
      assert_response :success
    end
  end

  def test_settings_exist
    for locale in I18n.available_locales
        assert Settings.country_codes.respond_to?(locale)
        assert Settings.language_codes.respond_to?(locale)
    end
  end
end
