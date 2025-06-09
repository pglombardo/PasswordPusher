# frozen_string_literal: true

require "application_system_test_case"
require "test_helper"

class LocaleStringsTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers

  setup do
    Settings.enable_logins = true
    Rails.application.reload_routes!

    # Create a user
    @user = users(:giuliana)
    @user.confirm
    sign_in @user

    # Get the test push from fixtures
    @push = pushes(:test_push)
    @push.payload = "test_payload"
    @push.save!
  end

  teardown do
    sign_out :user
  end

  test "audit page works in all configured locales" do
    # Test audit page in each configured locale
    I18n.available_locales.each do |locale|
      visit audit_push_path(@push, locale: locale)
      assert_not_includes page.body, "Apologies, it looks like something went wrong.", "Error found in locale: #{locale}"
    end
  end

  test "show push#show works in all configured locales" do
    # Test show page in each configured locale
    I18n.available_locales.each do |locale|
      visit push_path(@push, locale: locale)
      assert_not_includes page.body, "Apologies, it looks like something went wrong.", "Error found in locale: #{locale}"
    end
  end

  test "show root page works in all configured locales" do
    # Test show page in each configured locale
    I18n.available_locales.each do |locale|
      visit root_path(locale: locale)
      assert_not_includes page.body, "Apologies, it looks like something went wrong.", "Error found in locale: #{locale}"
    end
  end
end
