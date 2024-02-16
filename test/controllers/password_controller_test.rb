# frozen_string_literal: true

require "test_helper"

class PasswordControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Settings.enable_logins = true
  end

  teardown do
    @luca = users(:luca)
    sign_out @luca
  end

  test "New push form is available anonymous" do
    get new_password_path
    assert_response :success
    assert response.body.include?("Tip: Only enter a password into the box")
  end

  test '"active" and "expired" should redirect anonymous to user sign in' do
    get active_passwords_path
    assert_response :redirect
    follow_redirect!
    assert response.body.include?("You need to sign in or sign up before continuing.")

    get expired_passwords_path
    assert_response :redirect
    follow_redirect!
    assert response.body.include?("You need to sign in or sign up before continuing.")
  end

  test "logged in users can access their dashboard" do
    @luca = users(:luca)
    @luca.confirm
    sign_in @luca

    get active_passwords_path
    assert_response :success
    assert response.body.include?("You currently have no active password pushes.")

    get expired_passwords_path
    assert_response :success
    assert response.body.include?("You currently have no expired password pushes.")
  end

  test "logged in users with pushes can access their dashboard" do
    @luca = users(:luca)
    @luca.confirm
    sign_in @luca

    get new_password_path
    assert_response :success
    assert response.body.include?("Tip: Only enter a password into the box")

    # rubocop:disable Layout/LineLength
    post passwords_path params: {
      password: {
        payload: "TCZHOiBJIGxlYXZlIHRoZXNlIGhpZGRlbiBtZXNzYWdlcyB0byB5b3UgYm90aCBzbyB0aGF0IHRoZXkgbWF5IGV4aXN0IGZvcmV2ZXIuIExvdmUgUGFwYS4="
      }
    }
    # rubocop:enable Layout/LineLength
    assert_response :redirect

    get active_passwords_path
    assert_response :success
    assert_not response.body.include?("You currently have no active password pushes.")
  end

  test "get active dashboard with token" do
    @luca = users(:luca)
    @luca.confirm

    get active_passwords_path, headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}
    assert_response :success
  end

  test "get expired dashboard with token" do
    @luca = users(:luca)
    @luca.confirm

    get expired_passwords_path, headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}
    assert_response :success
  end
end
