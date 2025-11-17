# frozen_string_literal: true

require "test_helper"

class LanguageHelperTest < ActionView::TestCase
  include LanguageHelper

  setup do
    @original_available_locales = I18n.available_locales.dup
    @original_language_codes = Settings.language_codes.dup
  end

  teardown do
    I18n.available_locales = @original_available_locales
    Settings.language_codes = @original_language_codes
  end

  test "language_options_for_select returns array of language code and locale pairs" do
    I18n.available_locales = [:en, :es, :fr]
    Settings.language_codes = {
      en: "English",
      es: "Español",
      fr: "Français"
    }

    result = language_options_for_select

    assert_equal 3, result.length
    assert_includes result, ["English", :en]
    assert_includes result, ["Español", :es]
    assert_includes result, ["Français", :fr]
  end

  test "language_options_for_select handles single locale" do
    I18n.available_locales = [:en]
    Settings.language_codes = {en: "English"}

    result = language_options_for_select

    assert_equal 1, result.length
    assert_equal [["English", :en]], result
  end

  test "language_options_for_select handles empty locales" do
    # Note: I18n.available_locales cannot be set to empty array in practice,
    # but we can test with a minimal set
    I18n.available_locales.dup
    # Temporarily stub to return empty array
    I18n.stub(:available_locales, []) do
      result = language_options_for_select
      assert_equal 0, result.length
      assert_equal [], result
    end
  end

  test "language_options_for_select handles missing language code in settings" do
    I18n.available_locales = [:en, :es, :fr]
    Settings.language_codes = {
      en: "English",
      es: "Español"
      # fr is missing
    }

    result = language_options_for_select

    assert_equal 3, result.length
    assert_includes result, ["English", :en]
    assert_includes result, ["Español", :es]
    # fr should have nil as language code
    fr_entry = result.find { |entry| entry[1] == :fr }
    assert_not_nil fr_entry
    assert_nil fr_entry[0]
  end

  test "language_options_for_select handles complex locale codes" do
    I18n.available_locales = [:en, :"en-GB", :"pt-BR"]
    Settings.language_codes = {
      en: "English",
      "en-GB": "English (UK)",
      "pt-BR": "Português (Brasil)"
    }

    result = language_options_for_select

    assert_equal 3, result.length
    assert_includes result, ["English", :en]
    assert_includes result, ["English (UK)", :"en-GB"]
    assert_includes result, ["Português (Brasil)", :"pt-BR"]
  end

  test "language_options_for_select returns correct format for select options" do
    I18n.available_locales = [:en, :es]
    Settings.language_codes = {
      en: "English",
      es: "Español"
    }

    result = language_options_for_select

    # Each entry should be [display_name, value] format suitable for options_for_select
    result.each do |entry|
      assert_equal 2, entry.length
      assert entry[0].is_a?(String), "First element should be a string (display name)"
      assert entry[1].is_a?(Symbol), "Second element should be a symbol (locale)"
    end
  end
end
