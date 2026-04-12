# frozen_string_literal: true

require "test_helper"

class NotifyEmailsFieldVisibilityTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @default_disable_logins = Settings.disable_logins
    @default_enable_user_account_emails = Settings.enable_user_account_emails
    Settings.disable_logins = false
    Settings.enable_user_account_emails = true
    @user = users(:luca)
  end

  teardown do
    Settings.disable_logins = @default_disable_logins
    Settings.enable_user_account_emails = @default_enable_user_account_emails
  end

  test "notify emails field visible when user account emails enabled, logins enabled, and signed in" do
    sign_in @user
    get new_push_path(tab: "text")
    assert_response :success
    assert_select "input[name=?]", "push[notify_emails_to]", count: 1
  end

  test "notify emails field hidden when user account emails disabled" do
    Settings.enable_user_account_emails = false
    sign_in @user
    get new_push_path(tab: "text")
    assert_response :success
    assert_select "input[name=?]", "push[notify_emails_to]", count: 0
  end

  test "notify emails field hidden when not signed in" do
    get new_push_path(tab: "text")
    assert_response :success
    assert_select "input[name=?]", "push[notify_emails_to]", count: 0
  end

  test "notify emails field hidden when logins are disabled" do
    Settings.disable_logins = true
    sign_in @user
    get new_push_path(tab: "text")
    assert_response :success
    assert_select "input[name=?]", "push[notify_emails_to]", count: 0
  end

  test "new text push form includes notify emails copy and secret-link locale dropdown" do
    sign_in @user
    get new_push_path(tab: "text")
    assert_response :success
    assert_match(/Auto Dispatch: Send This Secret Link To/i, response.body)
    assert_match(/Enter email\(s\) separated by commas/i, response.body)
    assert_match(/Secret Link Language/i, response.body)
    assert_match(/Autodetect the recipient/i, response.body)
  end
end
