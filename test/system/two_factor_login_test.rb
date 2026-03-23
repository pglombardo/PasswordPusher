# frozen_string_literal: true

require "application_system_test_case"
require "rotp"

class TwoFactorLoginTest < ApplicationSystemTestCase
  include ActiveSupport::Testing::TimeHelpers

  setup do
    @previous_disable_logins = Settings.disable_logins

    # Same-process Puma sees frozen time, so ROTP codes match server verification (no 30s boundary races).
    travel_to Time.utc(2024, 6, 1, 12, 0, 0)

    Capybara.reset_sessions! if defined?(Capybara)
    Settings.disable_logins = false
    @user = users(:two)
    @user.update!(
      otp_secret: "JBSWY3DPEHPK3PXP",
      otp_required_for_login: true,
      last_otp_timestep: nil,
      otp_backup_code_digests: []
    )
  end

  teardown do
    Settings.disable_logins = @previous_disable_logins
    travel_back
  end

  def totp_code_for(user)
    ROTP::TOTP.new(user.otp_secret, issuer: user.totp_issuer).at(Time.now).to_s.rjust(6, "0")
  end

  test "two-factor required after password" do
    visit new_user_session_path
    fill_in "user_email", with: @user.email
    fill_in "user_password", with: "password12345"
    click_button I18n.t("devise.general.login")
    assert_field "otp_attempt", wait: 10
    assert_selector "h2", text: "Two-factor authentication", wait: 10
  end

  test "login succeeds with valid totp" do
    visit new_user_session_path
    fill_in "user_email", with: @user.email
    fill_in "user_password", with: "password12345"
    click_button I18n.t("devise.general.login")
    fill_in "otp_attempt", with: totp_code_for(@user)
    click_button "Verify"
    assert_current_path root_path, wait: 10
  end

  test "login fails with invalid totp" do
    visit new_user_session_path
    fill_in "user_email", with: @user.email
    fill_in "user_password", with: "password12345"
    click_button I18n.t("devise.general.login")
    # Avoid numeric-only codes that could accidentally match the current TOTP window.
    fill_in "otp_attempt", with: "notatotp"
    click_button "Verify"
    assert_text "Two-factor authentication"
    assert_text "Incorrect verification code."
  end

  test "login succeeds with backup code" do
    @user.update!(
      otp_backup_code_digests: [User.digest_otp_backup_code(@user.id, "feedface01")]
    )
    visit new_user_session_path
    fill_in "user_email", with: @user.email
    fill_in "user_password", with: "password12345"
    click_button I18n.t("devise.general.login")
    fill_in "otp_attempt", with: "feedface01"
    click_button "Verify"
    assert_current_path root_path, wait: 10
  end
end
