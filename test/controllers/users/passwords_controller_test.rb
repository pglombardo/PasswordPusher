# frozen_string_literal: true

require "test_helper"

class Users::PasswordsControllerTest < ActionController::TestCase
  tests Users::PasswordsController

  setup do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  test "sign_in_after_reset_password? is false when two-factor is required" do
    user = users(:one)
    user.update!(
      otp_required_for_login: true,
      otp_secret: "JBSWY3DPEHPK3PXP",
      otp_backup_code_digests: [],
      last_otp_timestep: nil
    )
    @controller.instance_variable_set(:@user, user)
    assert_not @controller.send(:sign_in_after_reset_password?)
  end

  test "sign_in_after_reset_password? is true when two-factor is not required" do
    user = users(:one)
    user.update!(
      otp_required_for_login: false,
      otp_secret: nil,
      otp_backup_code_digests: [],
      last_otp_timestep: nil
    )
    @controller.instance_variable_set(:@user, user)
    assert @controller.send(:sign_in_after_reset_password?)
  end
end
