# frozen_string_literal: true

require "test_helper"

class DisableLoginsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:luca)
  end

  teardown do
    Settings.disable_logins = false
    Settings.enable_file_pushes = false
    Rails.application.reload_routes!
    sign_out :user if respond_to?(:sign_out)
  end

  test "GET sign_in returns 404 when disable_logins is true" do
    Settings.disable_logins = true

    get new_user_session_path
    assert_response :not_found
  end

  test "POST sign_in returns 404 when disable_logins is true" do
    Settings.disable_logins = true

    post user_session_path, params: {user: {email: @user.email, password: "password12345"}}
    assert_response :not_found
  end

  test "GET sign_in succeeds when disable_logins is false" do
    Settings.disable_logins = false

    get new_user_session_path
    assert_response :success
  end

  test "GET new push with files tab redirects to text when disable_logins is true" do
    Settings.disable_logins = true
    Settings.enable_file_pushes = true
    Rails.application.reload_routes!

    get new_push_path(tab: "files")
    assert_redirected_to new_push_path(tab: "text")
  ensure
    Settings.enable_file_pushes = false
    Rails.application.reload_routes!
  end

  test "DELETE sign_out still works when disable_logins is true" do
    # reject_when_logins_disabled only applies to new/create; existing sessions must sign out
    Settings.disable_logins = false
    sign_in @user

    Settings.disable_logins = true
    delete destroy_user_session_path
    assert_response :redirect
    assert_redirected_to root_path

    follow_redirect!
    assert_response :success
  end

  test "root page does not include Log In link when disable_logins is true" do
    Settings.disable_logins = true
    sign_out :user

    get root_path
    assert_response :success
    assert_select "a[href='#{new_user_session_path}']", count: 0
  end

  test "root page includes Log In link when disable_logins is false" do
    Settings.disable_logins = false
    sign_out :user

    get root_path
    assert_response :success
    assert_select "a[href='#{new_user_session_path}']", minimum: 1
  end

  test "new push page omits Files tab link when disable_logins is true" do
    Settings.disable_logins = true
    Settings.enable_file_pushes = true
    Rails.application.reload_routes!
    sign_out :user

    get new_push_path(tab: "text")
    assert_response :success
    # No nav link to files tab when logins disabled (file pushes require sign-in)
    assert_select "a[href='#{new_push_path(tab: "files")}']", count: 0
  ensure
    Settings.enable_file_pushes = false
    Rails.application.reload_routes!
  end

  test "new push page includes Files tab link when disable_logins is false and file pushes enabled" do
    Settings.disable_logins = false
    Settings.enable_file_pushes = true
    Rails.application.reload_routes!
    sign_in @user

    get new_push_path(tab: "text")
    assert_response :success
    assert_select "a[href='#{new_push_path(tab: "files")}']", minimum: 1
  ensure
    Settings.enable_file_pushes = false
    Rails.application.reload_routes!
  end

  test "POST create file push redirects to text tab when disable_logins is true" do
    Settings.disable_logins = true
    Settings.enable_file_pushes = true
    Rails.application.reload_routes!
    sign_in @user

    post pushes_path, params: {
      push: {
        kind: "file",
        payload: "Message",
        files: [fixture_file_upload("monkey.png", "image/jpeg")]
      }
    }
    assert_redirected_to new_push_path(tab: "text")
    assert_equal I18n._("File pushes require sign in."), flash[:notice]
  ensure
    Settings.enable_file_pushes = false
    Rails.application.reload_routes!
  end
end
