# frozen_string_literal: true

require "test_helper"

class LocalesTest < ActionDispatch::IntegrationTest
  def test_locales_exist
    I18n.available_locales.each do |locale|
      get root_path, params: {locale:}
      assert_response :success
    end
  end

  def test_settings_exist
    I18n.available_locales.each do |locale|
      assert Settings.country_codes.respond_to?(locale)
      assert Settings.language_codes.respond_to?(locale)
    end
  end
end
