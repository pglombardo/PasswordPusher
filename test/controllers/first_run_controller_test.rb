# frozen_string_literal: true

require "test_helper"

class FirstRunControllerTest < ActionDispatch::IntegrationTest
  def run
    stub_boot_code_file do
      super
    end
  end

  # Stub the boot code file to ensure that all parallelization tests are run independently
  def stub_boot_code_file
    boot_code_file = FirstRunBootCode::BOOT_CODE_FILE.dup
    boot_code_file = boot_code_file.sub(".txt", "_#{ENV.fetch("TEST_WORKER_NUMBER", "")}.txt")

    stub_const(FirstRunBootCode, :BOOT_CODE_FILE, boot_code_file) do
      yield
    end
  end

  setup do
    Settings.disable_signups = false
    Rails.application.reload_routes!

    User.destroy_all
    FirstRunBootCode.clear!
  end

  teardown do
    User.destroy_all
    FirstRunBootCode.clear!
    Settings.disable_logins = false
    Settings.disable_signups = false
  end

  test "any page redirects to first run when no users exist" do
    get new_push_url
    assert_redirected_to first_run_url

    get root_url
    assert_redirected_to first_run_url
  end

  test "does not redirect to first run when logins and signups disabled and no users" do
    Settings.disable_logins = true
    Settings.disable_signups = true

    get root_url
    refute response.redirect? && response.redirect_url == first_run_url

    get new_push_url
    refute response.redirect? && response.redirect_url == first_run_url
  end

  test "boot code file is not created when logins and signups disabled and no users" do
    Settings.disable_logins = true
    Settings.disable_signups = true

    get root_url
    assert_not File.exist?(FirstRunBootCode::BOOT_CODE_FILE)
  end

  test "first run page redirects to root when logins and signups disabled and no users" do
    Settings.disable_logins = true
    Settings.disable_signups = true

    get first_run_url
    assert_redirected_to root_url
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
    assert_user_confirmed(user)
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
