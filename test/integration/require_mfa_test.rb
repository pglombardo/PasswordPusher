# frozen_string_literal: true

require "test_helper"

class RequireMfaTest < ActionDispatch::IntegrationTest
  setup do
    @previous_require_mfa = Settings.require_mfa
    @user = users(:one)
  end

  teardown do
    Settings.require_mfa = @previous_require_mfa
    sign_out :user if respond_to?(:sign_out)
  end

  test "signed in users without two-factor are redirected when require_mfa is true" do
    Settings.require_mfa = true
    @user.update!(
      otp_required_for_login: false,
      otp_secret: nil,
      otp_backup_code_digests: [],
      last_otp_timestep: nil
    )
    sign_in @user

    get root_path

    assert_redirected_to backup_codes_user_two_factor_path
    assert_equal I18n._("Two-factor authentication is required. Please set it up to continue."), flash[:alert]
  end

  test "two-factor setup pages remain accessible while require_mfa is true" do
    Settings.require_mfa = true
    @user.update!(
      otp_required_for_login: false,
      otp_secret: nil,
      otp_backup_code_digests: [],
      last_otp_timestep: nil
    )
    sign_in @user

    get backup_codes_user_two_factor_path

    assert_response :success
  end

  test "account edit is blocked until two-factor setup when require_mfa is true" do
    Settings.require_mfa = true
    @user.update!(
      otp_required_for_login: false,
      otp_secret: nil,
      otp_backup_code_digests: [],
      last_otp_timestep: nil
    )
    sign_in @user

    get edit_user_registration_path

    assert_redirected_to backup_codes_user_two_factor_path
    assert_equal I18n._("Two-factor authentication is required. Please set it up to continue."), flash[:alert]
  end

  test "api token page is blocked until two-factor setup when require_mfa is true" do
    Settings.require_mfa = true
    @user.update!(
      otp_required_for_login: false,
      otp_secret: nil,
      otp_backup_code_digests: [],
      last_otp_timestep: nil
    )
    sign_in @user

    get token_user_registration_path

    assert_redirected_to backup_codes_user_two_factor_path
    assert_equal I18n._("Two-factor authentication is required. Please set it up to continue."), flash[:alert]
  end

  test "signed in users with two-factor enabled are not redirected when require_mfa is true" do
    Settings.require_mfa = true
    @user.update!(
      otp_required_for_login: true,
      otp_secret: "JBSWY3DPEHPK3PXP",
      otp_backup_code_digests: [],
      last_otp_timestep: nil
    )
    sign_in @user

    get root_path

    assert_response :success
  end

  test "two-factor cannot be disabled when require_mfa is true" do
    Settings.require_mfa = true
    @user.update!(
      otp_required_for_login: true,
      otp_secret: "JBSWY3DPEHPK3PXP",
      otp_backup_code_digests: [],
      last_otp_timestep: nil
    )
    sign_in @user

    delete user_two_factor_path

    assert_redirected_to edit_user_registration_path
    assert_equal I18n._("Two-factor authentication cannot be disabled because it is required by the administrator."), flash[:alert]
    assert @user.reload.otp_required_for_login?
  end

  test "two-factor can be disabled when require_mfa is false" do
    Settings.require_mfa = false
    @user.update!(
      otp_required_for_login: true,
      otp_secret: "JBSWY3DPEHPK3PXP",
      otp_backup_code_digests: [],
      last_otp_timestep: nil
    )
    sign_in @user

    delete user_two_factor_path

    assert_redirected_to edit_user_registration_path
    assert_equal I18n._("Two-factor authentication has been disabled."), flash[:notice]
    assert_not @user.reload.otp_required_for_login?
  end
end
