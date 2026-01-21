# frozen_string_literal: true

require "application_system_test_case"

class FirstRunTest < ApplicationSystemTestCase
  setup do
    Settings.enable_logins = true
    Settings.disable_signups = false
    Rails.application.reload_routes!

    @original_timestamp_enabled = InvisibleCaptcha.timestamp_enabled
    @original_spinner_enabled = InvisibleCaptcha.spinner_enabled
    InvisibleCaptcha.timestamp_enabled = false
    InvisibleCaptcha.spinner_enabled = false

    User.destroy_all
    FirstRunBootCode.clear!
  end

  teardown do
    FirstRunBootCode.clear!
    Settings.enable_logins = false
    Settings.disable_signups = false

    InvisibleCaptcha.timestamp_enabled = @original_timestamp_enabled
    InvisibleCaptcha.spinner_enabled = @original_spinner_enabled
  end

  test "redirects to first run when visiting other pages and no users exist" do
    visit root_path
    assert_current_path first_run_path

    visit new_push_path
    assert_current_path first_run_path
  end

  test "redirects to root when accessing first run page and users exist" do
    User.create!(
      email: "existing@example.com",
      password: "password123",
      confirmed_at: Time.current,
      admin: true
    )

    visit first_run_path
    assert_current_path root_path
  end

  test "successfully creates first admin user through first run" do
    visit first_run_path

    assert_text "Boot Code Required"
    assert_selector "input[name='user[boot_code]']", wait: 5

    code = FirstRunBootCode.code
    assert_not_nil code, "Boot code should be generated"
    assert_not_empty code, "Boot code should not be empty"
    assert File.exist?(FirstRunBootCode::BOOT_CODE_FILE), "Boot code file should exist"

    fill_in "Boot Code", with: code
    fill_in "Email", with: "admin@example.com"
    fill_in "Password", with: "securepassword123"

    click_button "Create Admin Account"

    assert_text "Administrator account created successfully!", wait: 10
    assert_not File.exist?(FirstRunBootCode::BOOT_CODE_FILE), "Boot code file should be cleared"
    assert_equal 1, User.count
    user = User.last
    assert_equal "admin@example.com", user.email
    assert user.confirmed?
    assert user.admin?
  end

  test "requires boot code to create first user" do
    visit first_run_path

    fill_in "Boot Code", with: "invalid-boot-code-12345"
    fill_in "Email", with: "admin@example.com"
    fill_in "Password", with: "securepassword123"

    click_button "Create Admin Account"

    assert_current_path first_run_path, wait: 5
    assert_selector ".alert-warning, .alert-danger", wait: 5
    assert_text(/Invalid.*boot code|boot code/i, wait: 5)
    assert_equal 0, User.count
  end

  test "shows validation error for short password" do
    visit first_run_path

    code = FirstRunBootCode.code
    fill_in "Boot Code", with: code
    fill_in "Email", with: "admin@example.com"
    fill_in "Password", with: "123"

    click_button "Create Admin Account"

    assert_current_path first_run_path, wait: 5
    assert_selector ".alert-danger", wait: 5
    assert_text(/too short|minimum|password/i, wait: 5)
    assert_equal 0, User.count
  end

  test "shows validation error for invalid email" do
    visit first_run_path

    code = FirstRunBootCode.code
    fill_in "Boot Code", with: code
    fill_in "Email", with: "invalid-email"
    fill_in "Password", with: "securepassword123"

    # Disable native HTML5 validation so the server-side error is returned.
    page.execute_script("document.querySelector('form').setAttribute('novalidate','novalidate')")
    click_button "Create Admin Account"

    assert_current_path first_run_path, wait: 5
    assert_selector ".alert-danger", wait: 5
    assert_text(/email|invalid/i, wait: 5)
    assert_equal 0, User.count
  end

  test "form includes invisible captcha for spam protection" do
    visit first_run_path
    assert_selector "input[tabindex='-1'][autocomplete='off']", visible: false
  end
end
