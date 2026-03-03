# frozen_string_literal: true

require "test_helper"

class FirstRunControllerTest < ActionDispatch::IntegrationTest
  setup do
    Settings.enable_logins = true
    Settings.disable_signups = false
    Rails.application.reload_routes!

    User.destroy_all
    FirstRunBootCode.clear!

    @original_timestamp_enabled = InvisibleCaptcha.timestamp_enabled
    @original_spinner_enabled = InvisibleCaptcha.spinner_enabled
    InvisibleCaptcha.timestamp_enabled = false
    InvisibleCaptcha.spinner_enabled = false
  end

  teardown do
    User.destroy_all
    FirstRunBootCode.clear!
    InvisibleCaptcha.timestamp_enabled = @original_timestamp_enabled
    InvisibleCaptcha.spinner_enabled = @original_spinner_enabled
    Settings.enable_logins = false
    Settings.disable_signups = false
  end

  test "any page redirects to first run when no users exist" do
    get new_push_url
    assert_redirected_to first_run_url

    get root_url
    assert_redirected_to first_run_url
  end

  test "first run page is accessible when no users exist" do
    get first_run_url
    assert_response :success
  end

  test "first run create rejects invalid boot code" do
    post first_run_url, params: {user: {email: "test@example.com", password: "password123", boot_code: "bad-code"}}

    assert_response :unprocessable_content
    assert_match(/Invalid or missing boot code/i, response.body)
    assert_equal 0, User.where(email: "test@example.com").count
  end

  test "first run create accepts valid boot code" do
    code = FirstRunBootCode.code

    assert_difference -> { User.where(email: "test@example.com").count }, 1 do
      post first_run_url, params: {user: {email: "test@example.com", password: "password123", boot_code: code}}
    end

    assert_response :redirect
    user = User.order(:created_at).last
    assert user.admin?
    assert user.confirmed?
    assert_equal user.id, session["warden.user.user.key"]&.dig(0, 0)
    assert_not File.exist?(FirstRunBootCode::BOOT_CODE_FILE)
  end

  test "first run page is not accessible when users exist" do
    User.create!(
      email: "existing@example.com",
      password: "password123",
      confirmed_at: Time.current,
      admin: true
    )

    get first_run_url
    assert_redirected_to root_url

    assert_no_difference "User.count" do
      post first_run_url, params: {user: {email: "test@example.com", password: "password"}}
      assert_redirected_to root_url
    end
  end
end
