# frozen_string_literal: true

require "test_helper"

class UrlControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Settings.enable_logins = true
    Settings.enable_url_pushes = true
    Rails.application.reload_routes!
  end

  teardown do
    @luca = users(:luca)
    sign_out @luca
  end

  test "New push form is NOT available anonymous" do
    get new_url_path
    assert_response :success
    assert response.body.include?("Please login or sign up to use this feature.")
  end

  test '"active" and "expired" should redirect anonymous to user sign in' do
    get active_urls_path
    assert_response :redirect
    follow_redirect!
    assert response.body.include?("You need to sign in or sign up before continuing.")

    get expired_urls_path
    assert_response :redirect
    follow_redirect!
    assert response.body.include?("You need to sign in or sign up before continuing.")
  end

  test "logged in users can access their dashboard" do
    @luca = users(:luca)
    @luca.confirm
    sign_in @luca

    get active_urls_path
    assert_response :success
    assert response.body.include?("You currently have no active URL pushes.")

    get expired_urls_path
    assert_response :success
    assert response.body.include?("You currently have no expired URL pushes.")
  end

  test "logged in users with pushes can access their dashboard" do
    @luca = users(:luca)
    @luca.confirm
    sign_in @luca

    get new_url_path
    assert_response :success
    assert response.body.include?("URL Redirection")

    post urls_path params: {
      url: {
        payload: "https://the0x00.dev"
      }
    }
    assert_response :redirect

    get active_urls_path
    assert_response :success
    assert_not response.body.include?("You currently have no active url pushes.")
  end

  test "get active dashboard with token" do
    @luca = users(:luca)
    @luca.confirm

    get active_urls_path, headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}
    assert_response :success
  end

  test "get expired dashboard with token" do
    @luca = users(:luca)
    @luca.confirm

    get expired_urls_path, headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}
    assert_response :success
  end
end
