# frozen_string_literal: true

require "application_system_test_case"

class SecretUrlBarTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers

  setup do
    # Enable logins for these tests
    Settings.enable_logins = true
    Rails.application.reload_routes!

    # Create and sign in a user
    @user = users(:giuliana)
    @user.confirm
    sign_in @user

    # Create a test push
    @push = pushes(:test_push)
    @push.payload = "test secret content"
    @push.save!
  end

  teardown do
    sign_out :user
  end

  test "language dropdown shows available locales" do
    # Skip if language codes are not configured
    skip "Language codes not configured" unless Settings.language_codes

    visit preview_push_path(@push)

    # Click the language dropdown button
    find("button.dropdown-toggle").click

    # Check that language options are present for each available locale
    I18n.available_locales.each do |locale|
      # Look for the language name in the dropdown
      if Settings.language_codes[locale]
        assert_selector "a.dropdown-item", text: Settings.language_codes[locale]
      end
    end
  end

  test "clicking language option updates URL with locale parameter" do
    visit preview_push_path(@push)

    # Click the language dropdown button
    find("button.dropdown-toggle").click

    click_link "Deutsch"

    # Check that the URL now includes the push_locale parameter
    assert_current_path preview_push_path(@push, push_locale: "de")

    # Check that the secret URL input field value has been updated with locale
    secret_url_input = find("input#secret_url")
    assert_includes secret_url_input.value, "locale=de"
  end

  test "language dropdown button shows selected language flag and name" do
    visit preview_push_path(@push, push_locale: "es")

    # Check that the dropdown button shows the flag and language name
    dropdown_button = find("button.dropdown-toggle")

    # Check for flag (country code class)
    assert_selector "button.dropdown-toggle em.fi-#{Settings.country_codes["es"]}"

    # Check for language name
    assert_includes dropdown_button.text, "Español"
  end

  test "language dropdown button shows globe icon when no locale is selected" do
    # Skip if language codes are not configured
    skip "Language codes not configured" unless Settings.language_codes

    visit preview_push_path(@push)

    # Without a push_locale parameter, should show globe icon
    dropdown_button = find("button.dropdown-toggle")
    assert_includes dropdown_button.text, "🌎"
  end
end
