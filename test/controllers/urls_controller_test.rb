# frozen_string_literal: true

require "test_helper"

class UrlsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Settings.enable_url_pushes = true
    Rails.application.reload_routes!
  end

  teardown do
    @luca = users(:luca)
    sign_out @luca
  end

  test "New push form is available when anonymous" do
    get new_push_path(tab: "url")
    assert_response :success
  end

  test '"index" should redirect anonymous to user sign in' do
    get pushes_path
    assert_response :redirect
    follow_redirect!
    assert response.body.include?("You need to sign in or sign up before continuing.")
  end

  test "logged in users can access their dashboard" do
    @luca = users(:luca)
    sign_in @luca

    get pushes_path
    assert_response :success
    assert response.body.include?("No pushes yet")

    get pushes_path(filter: "active")
    assert_response :success
    assert response.body.include?("No active pushes")

    get pushes_path(filter: "expired")
    assert_response :success
    assert response.body.include?("No expired pushes")
  end

  test "logged in users with pushes can access their dashboard" do
    @luca = users(:luca)
    sign_in @luca

    no_push_text = "No pushes yet"
    get pushes_path
    assert_response :success
    assert response.body.include?(no_push_text)

    get new_push_path(tab: "url")
    assert_response :success
    assert response.body.include?("URL Redirection")

    post pushes_path params: {
      push: {
        kind: "url",
        payload: "https://the0x00.dev"
      }
    }
    assert_response :redirect

    get pushes_path
    assert_response :success
    assert_not response.body.include?(no_push_text)
  end

  test "get active dashboard with token" do
    @luca = users(:luca)
    get active_urls_path(format: :json), headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}
    assert_response :success
  end

  test "get expired dashboard with token" do
    @luca = users(:luca)
    get expired_urls_path(format: :json), headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}
    assert_response :success
  end

  # When URL pushes are disabled (Settings.enable_url_pushes = false)
  test "when URL pushes disabled, new push form with tab url redirects to root with notice" do
    Settings.enable_url_pushes = false
    Rails.application.reload_routes!

    get new_push_path(tab: "url")

    assert_response :redirect
    assert_redirected_to root_path
    follow_redirect!
    assert_match(/URL pushes are disabled\./i, flash[:notice])
  ensure
    Settings.enable_url_pushes = true
    Rails.application.reload_routes!
  end

  test "when URL pushes disabled, creating a URL push redirects to root with notice" do
    Settings.enable_url_pushes = false
    Rails.application.reload_routes!

    post pushes_path, params: {
      push: {
        kind: "url",
        payload: "https://example.com"
      }
    }

    assert_redirected_to root_path
    assert_equal I18n._("URL pushes are disabled."), flash[:notice]
  ensure
    Settings.enable_url_pushes = true
    Rails.application.reload_routes!
  end

  test "when URL pushes disabled, logged-in user creating URL push redirects to root with notice" do
    Settings.enable_url_pushes = false
    Rails.application.reload_routes!
    @luca = users(:luca)
    sign_in @luca

    post pushes_path, params: {
      push: {
        kind: "url",
        payload: "https://example.com"
      }
    }

    assert_redirected_to root_path
    assert_equal I18n._("URL pushes are disabled."), flash[:notice]
  ensure
    Settings.enable_url_pushes = true
    Rails.application.reload_routes!
  end
end
