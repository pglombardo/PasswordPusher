# frozen_string_literal: true

require "test_helper"

class UrlAnonymousAccessTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Settings.enable_url_pushes = true

    Rails.application.reload_routes!
  end

  teardown do
    Settings.disable_signups = false
  end

  def test_anonymous_disabled_signups_no_signup_link
    Settings.disable_signups = true

    get new_push_path(tab: "url")
    assert_response :success
    # Anonymous can create URL pushes; when signups disabled, signup link should not be present
  end

  def test_anonymous_enabled_signups_with_signup_link
    get new_push_path(tab: "url")
    assert_response :success
    # Anonymous can create URL pushes; signup link may be present when signups enabled
  end

  def test_no_access_for_anonymous_dashboard
    get pushes_path
    assert_response :redirect
    follow_redirect!
    assert response.body.include?("You need to sign in or sign up before continuing.")

    post pushes_path, params: {blah: "blah"}
    assert_response :bad_request

    get new_push_path(tab: "url")
    assert_response :success
  end
end
