# frozen_string_literal: true

require "test_helper"

class QrPushControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Settings.enable_logins = true
    Settings.enable_qr_pushes = true
  end

  teardown do
    @luca = users(:luca)
    sign_out @luca
  end

  test "New push form is NOT available anonymous" do
    get new_push_path(tab: "qr")
    assert_redirected_to new_user_session_path
  end

  test '"index" should redirect anonymous to user sign in' do
    get pushes_path
    assert_response :redirect
    follow_redirect!
    assert response.body.include?("You need to sign in or sign up before continuing.")
  end

  test "logged in users can access their dashboard" do
    @luca = users(:luca)
    @luca.confirm
    sign_in @luca

    get pushes_path
    assert_response :success
    assert response.body.include?("You currently have no pushes.")

    get pushes_path(filter: "active")
    assert_response :success
    assert response.body.include?("You currently have no active pushes.")

    get pushes_path(filter: "expired")
    assert_response :success
    assert response.body.include?("You currently have no expired pushes.")
  end

  test "logged in users with pushes can access their dashboard" do
    @luca = users(:luca)
    @luca.confirm
    sign_in @luca

    no_push_text = "You currently have no pushes."
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
    @luca.confirm

    get active_json_pushes_path(format: :json),
      headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}
    assert_response :success
  end

  test "get expired dashboard with token" do
    @luca = users(:luca)
    @luca.confirm

    get expired_json_pushes_path(format: :json),
      headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}
    assert_response :success
  end

  test "override base url" do
    Settings.override_base_url = "https://example.com:12345"

    @luca = users(:luca)
    @luca.confirm
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
end
