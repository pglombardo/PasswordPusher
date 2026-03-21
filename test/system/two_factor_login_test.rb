# frozen_string_literal: true

require "application_system_test_case"
require "rotp"

class TwoFactorLoginTest < ApplicationSystemTestCase
  setup do
    Capybara.reset_sessions! if defined?(Capybara)
    Settings.disable_logins = false
    @user = users(:two)
    @user.update!(
      otp_secret: "JBSWY3DPEHPK3PXP",
      otp_required_for_login: true,
      last_otp_timestep: nil,
      otp_backup_codes: []
    )
  end

  def totp_code_for(user)
    ROTP::TOTP.new(user.otp_secret, issuer: user.totp_issuer).at(Time.now).to_s.rjust(6, "0")
  end

  test "two-factor required after password" do
    visit new_user_session_path
    fill_in "user_email", with: @user.email
    fill_in "user_password", with: "password12345"
    click_button I18n.t("devise.general.login")
    assert_selector "h2", text: "Two-factor authentication"
  end

  test "login succeeds with valid totp" do
    visit new_user_session_path
    fill_in "user_email", with: @user.email
    fill_in "user_password", with: "password12345"
    click_button I18n.t("devise.general.login")
    fill_in "otp_attempt", with: totp_code_for(@user)
    click_button "Verify"
    assert_current_path root_path
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
    @user.update!(otp_backup_codes: ["feedface01"])
    visit new_user_session_path
    fill_in "user_email", with: @user.email
    fill_in "user_password", with: "password12345"
    click_button I18n.t("devise.general.login")
    fill_in "otp_attempt", with: "feedface01"
    click_button "Verify"
    assert_current_path root_path
  end
end
