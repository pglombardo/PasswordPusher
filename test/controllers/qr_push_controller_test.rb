# frozen_string_literal: true

require "test_helper"

class QrPushControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Settings.enable_qr_pushes = true
  end

  teardown do
    @luca = users(:luca)
    sign_out @luca
  end

  test "New push form is available when anonymous" do
    get new_push_path(tab: "qr")
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

    get new_push_path(tab: "qr")
    assert_response :success
    assert response.body.include?("Tip: Only enter a password into the box")

    post pushes_path params: {
      push: {
        kind: "qr",
        payload: "testqr"
      }
    }
    assert_response :redirect

    get pushes_path
    assert_response :success
    assert_not response.body.include?(no_push_text)
  end

  test "get active dashboard with token" do
    @luca = users(:luca)
    get active_json_pushes_path(format: :json),
      headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}
    assert_response :success
  end

  test "get expired dashboard with token" do
    @luca = users(:luca)
    get expired_json_pushes_path(format: :json),
      headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}
    assert_response :success
  end

  test "override base url" do
    Settings.override_base_url = "https://example.com:12345"

    @luca = users(:luca)
    sign_in @luca

    post pushes_path params: {
      push: {
        kind: "qr",
        payload: "testqr"
      }
    }
    assert_response :redirect

    follow_redirect!
    assert_response :success

    assert response.body.include?("https://example.com:12345")
  end

  # When QR pushes are disabled (Settings.enable_qr_pushes = false)
  test "when QR pushes disabled, new push form with tab qr redirects to root with notice" do
    Settings.enable_qr_pushes = false

    get new_push_path(tab: "qr")

    assert_response :redirect
    assert_redirected_to root_path
    follow_redirect!
    assert_match(/QR code pushes are disabled\./i, flash[:notice])
  ensure
    Settings.enable_qr_pushes = true
  end

  test "when QR pushes disabled, creating a QR push redirects to root with notice" do
    Settings.enable_qr_pushes = false

    post pushes_path, params: {
      push: {
        kind: "qr",
        payload: "testqr"
      }
    }

    assert_redirected_to root_path
    assert_equal I18n._("QR code pushes are disabled."), flash[:notice]
  ensure
    Settings.enable_qr_pushes = true
  end

  test "when QR pushes disabled, logged-in user creating QR push redirects to root with notice" do
    Settings.enable_qr_pushes = false
    @luca = users(:luca)
    sign_in @luca

    post pushes_path, params: {
      push: {
        kind: "qr",
        payload: "testqr"
      }
    }

    assert_redirected_to root_path
    assert_equal I18n._("QR code pushes are disabled."), flash[:notice]
  ensure
    Settings.enable_qr_pushes = true
  end
end
