# frozen_string_literal: true

require "test_helper"
require "rotp"

class SignInThrottleTest < ActionDispatch::IntegrationTest
  include ActiveSupport::Testing::TimeHelpers

  setup do
    @user = users(:two)
  end

  test "format suffixes on sign in are not routed" do
    %w[json xml].each do |format|
      post "/users/sign_in.#{format}", params: {
        user: {email: @user.email, password: "password12345"}
      }

      assert_response :not_found
      assert_not signed_in_session?, "POST /users/sign_in.#{format} must not create a session"
    end
  end

  test "JSON Accept on the unsuffixed sign in path is rejected before authentication" do
    post user_session_path, params: {
      user: {email: @user.email, password: "password12345"}
    }, as: :json

    assert_response :not_acceptable
    assert_not signed_in_session?
  end

  test "HTML sign in still authenticates" do
    post user_session_path, params: {
      user: {email: @user.email, password: "password12345"}
    }

    assert_response :see_other
    follow_redirect!
    assert_equal @user, controller.current_user
  end

  test "turbo sign out still succeeds" do
    sign_in @user

    delete destroy_user_session_path, as: :turbo_stream

    assert_response :see_other
    assert_not signed_in_session?
  end

  test "malformed user param is not a server error" do
    post user_session_path, params: {user: "invalid"}

    assert_not_equal 500, response.status
  end

  test "HTML sign in is throttled after five attempts" do
    5.times do
      post user_session_path, params: {
        user: {email: @user.email, password: "wrong-password"}
      }
      assert_response :unprocessable_content
    end

    post user_session_path, params: {
      user: {email: @user.email, password: "wrong-password"}
    }
    assert_response :too_many_requests
  end

  test "otp guesses from rotating addresses are limited per pending user" do
    enable_otp!
    start_otp_session!("203.0.113.1")

    5.times do |i|
      post_otp("notatotp", "203.0.113.#{10 + i}")
      assert_response :unprocessable_content
      assert_not signed_in_session?
    end

    post_otp("notatotp", "203.0.113.20")
    assert_response :too_many_requests
    assert_not signed_in_session?
  end

  test "a correct otp is rejected once the pending user is over the attempt limit" do
    enable_otp!
    start_otp_session!("203.0.113.1")

    5.times do |i|
      post_otp("notatotp", "198.51.100.#{10 + i}")
      assert_response :unprocessable_content
    end

    post_otp(totp_code_for(@user), "198.51.100.20")
    assert_response :too_many_requests
    assert_not signed_in_session?
  end

  test "submitting the password again does not reset the otp attempt limit" do
    enable_otp!
    start_otp_session!("203.0.113.1")

    5.times do |i|
      post_otp("notatotp", "198.51.100.#{30 + i}")
      assert_response :unprocessable_content
    end

    post user_session_path, params: {
      user: {email: @user.email, password: "password12345"}
    }, env: {"REMOTE_ADDR" => "203.0.113.60"}
    assert_response :unprocessable_content
    assert_not signed_in_session?

    post_otp(totp_code_for(@user), "203.0.113.61")
    assert_response :too_many_requests
    assert_not signed_in_session?
  end

  test "otp attempt limit allows a correct code again after the window" do
    enable_otp!
    start_otp_session!("203.0.113.1")

    5.times do |i|
      post_otp("notatotp", "198.51.100.#{40 + i}")
      assert_response :unprocessable_content
    end

    travel 21.seconds do
      post_otp(totp_code_for(@user), "203.0.113.70")
      assert_response :see_other
      follow_redirect!
      assert_equal @user, controller.current_user
    end
  end

  test "logins/email throttle keys on the nested Devise email param" do
    throttle = Rack::Attack.throttles.fetch("logins/email")

    nested = sign_in_request("user" => {"email" => " A@B.com "})
    assert_equal "a@b.com", throttle.block.call(nested)

    flat = sign_in_request("email" => "a@b.com")
    assert_nil throttle.block.call(flat)

    malformed = sign_in_request("user" => "invalid")
    assert_nil throttle.block.call(malformed)
  end

  private

  def signed_in_session?
    session["warden.user.user.key"].present?
  end

  def sign_in_request(params)
    env = Rack::MockRequest.env_for("/users/sign_in", method: "POST", params: params)
    Rack::Attack::Request.new(env)
  end

  def enable_otp!
    @user.update!(
      otp_secret: "JBSWY3DPEHPK3PXP",
      otp_required_for_login: true,
      last_otp_timestep: nil,
      otp_backup_code_digests: []
    )
  end

  def start_otp_session!(ip)
    post user_session_path, params: {
      user: {email: @user.email, password: "password12345"}
    }, env: {"REMOTE_ADDR" => ip}
    assert_response :unprocessable_content
    assert_not signed_in_session?
  end

  def post_otp(code, ip)
    post user_session_path, params: {otp_attempt: code}, env: {"REMOTE_ADDR" => ip}
  end

  def totp_code_for(user)
    ROTP::TOTP.new(user.otp_secret, issuer: user.totp_issuer).at(Time.now).to_s.rjust(6, "0")
  end
end
