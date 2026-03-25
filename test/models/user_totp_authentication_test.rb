# frozen_string_literal: true

require "test_helper"
require "rotp"

class UserTotpAuthenticationTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::TimeHelpers

  setup do
    travel_to Time.utc(2024, 6, 1, 12, 0, 0)
    @user = users(:two)
    @user.update!(
      otp_secret: "JBSWY3DPEHPK3PXP",
      otp_required_for_login: true,
      last_otp_timestep: nil,
      otp_backup_code_digests: []
    )
  end

  teardown do
    travel_back
  end

  def totp_code_for(user)
    ROTP::TOTP.new(user.otp_secret, issuer: user.totp_issuer).at(Time.now).to_s.rjust(6, "0")
  end

  test "verify_and_consume_otp! with valid TOTP updates last_otp_timestep and rejects replay" do
    code = totp_code_for(@user)
    assert_nil @user.reload.last_otp_timestep

    totp = ROTP::TOTP.new(@user.otp_secret, issuer: @user.totp_issuer)
    expected_epoch = totp.verify(code, after: nil).to_i

    assert @user.verify_and_consume_otp!(code)
    assert_equal expected_epoch, @user.reload.last_otp_timestep

    assert_not @user.verify_and_consume_otp!(code)
  end

  test "verify_and_consume_otp! accepts each backup code only once and removes its digest" do
    plaintext = "feedface01"
    digest = User.digest_otp_backup_code(@user.id, plaintext)
    @user.update!(otp_backup_code_digests: [digest])

    assert @user.verify_and_consume_otp!(plaintext)
    @user.reload
    assert_equal [], @user.otp_backup_code_digests

    assert_not @user.verify_and_consume_otp!(plaintext)
  end
end
