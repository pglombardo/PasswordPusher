# frozen_string_literal: true

require "test_helper"

class PasswordControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Settings.enable_logins = true
    Settings.enable_file_pushes = false
    Settings.enable_url_pushes = false
    @luca = users(:luca)
  end

  teardown do
    Settings.enable_logins = false
    Settings.enable_file_pushes = false
    Settings.enable_url_pushes = false
  end

  test "New push form is available anonymous" do
    get new_push_path(tab: "text")
    assert_response :success
    assert response.body.include?("Tip: Only enter a password into the box")
  end

  test '"index" should redirect anonymous to user sign in' do
    get pushes_path
    assert_response :redirect
    follow_redirect!
    assert response.body.include?("You need to sign in or sign up before continuing.")
  end

  test "logged in users can access their dashboard" do
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
    sign_in @luca

    no_push_text = "You currently have no pushes."
    get pushes_path
    assert_response :success
    assert response.body.include?(no_push_text)

    get new_push_path(tab: "text")
    assert_response :success
    assert response.body.include?("Tip: Only enter a password into the box")

    # rubocop:disable Layout/LineLength
    post pushes_path params: {
      push: {
        kind: "text",
        payload: "TCZHOiBJIGxlYXZlIHRoZXNlIGhpZGRlbiBtZXNzYWdlcyB0byB5b3UgYm90aCBzbyB0aGF0IHRoZXkgbWF5IGV4aXN0IGZvcmV2ZXIuIExvdmUgUGFwYS4="
      }
    }
    # rubocop:enable Layout/LineLength
    assert_response :redirect

    get pushes_path
    assert_response :success
    assert_not response.body.include?(no_push_text)
  end

  test "get active dashboard with token" do
    get active_passwords_path(format: :json),
      headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}
    assert_response :success
  end

  test "get expired dashboard with token" do
    get expired_passwords_path(format: :json),
      headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}
    assert_response :success
  end
end
