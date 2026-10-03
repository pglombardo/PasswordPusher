# frozen_string_literal: true

require "test_helper"

class SignInThrottleTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:two)
    Rack::Attack.cache.store.clear if defined?(Rack::Attack)
  end

  teardown do
    Rack::Attack.cache.store.clear if defined?(Rack::Attack)
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

  test "logins/email throttle keys on the nested Devise email param" do
    # rack-attack is only bundled outside the test group, so load it here.
    require "rack/attack"
    load Rails.root.join("config/initializers/rack_attack.rb")

    throttle = Rack::Attack.throttles.fetch("logins/email")

    nested = sign_in_request("user" => {"email" => " A@B.com "})
    assert_equal "a@b.com", throttle.block.call(nested)

    flat = sign_in_request("email" => "a@b.com")
    assert_nil throttle.block.call(flat)
  end

  private

  def signed_in_session?
    session["warden.user.user.key"].present?
  end

  def sign_in_request(params)
    env = Rack::MockRequest.env_for("/users/sign_in", method: "POST", params: params)
    Rack::Attack::Request.new(env)
  end
end
