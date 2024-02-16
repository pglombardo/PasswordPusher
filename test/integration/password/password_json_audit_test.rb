# frozen_string_literal: true

require "test_helper"

class PasswordJsonAuditTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def test_audit_response_for_authenticated
    Settings.enable_logins = true

    @luca = users(:luca)
    @luca.confirm

    # Create a push
    post passwords_path(format: :json), params: {password: {payload: "testpw", expire_after_views: 2}},
      headers: {"X-User-Email": @luca.email,
                "X-User-Token": @luca.authentication_token}, as: :json
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("url_token")
    url_token = res["url_token"]

    # Generate views on that push
    3.times do
      get "/p/#{url_token}.json"
      assert_response :success
    end

    # Get the Audit Log
    get "/p/#{url_token}/audit.json",
      headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}, as: :json
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("views")
    assert res["views"].length == 3

    first_view = res["views"].first
    assert first_view.key?("ip")
    assert first_view.key?("user_agent")
    assert first_view.key?("referrer")
    assert first_view.key?("successful")
    assert first_view.key?("created_at")
    assert first_view.key?("updated_at")
    assert first_view.key?("kind")
  end

  def test_no_token_no_audit_log
    Settings.enable_logins = true

    @luca = users(:luca)
    @luca.confirm

    # Create a push
    post passwords_path(format: :json), params: {password: {payload: "testpw", expire_after_views: 2}},
      headers: {"X-User-Email": @luca.email,
                "X-User-Token": @luca.authentication_token}, as: :json
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("url_token")
    url_token = res["url_token"]

    # Generate views on that push
    3.times do
      get "/p/#{url_token}.json"
      assert_response :success
    end

    # Get the Audit Log without a token
    get "/p/#{url_token}/audit.json", as: :json
    assert_response :unauthorized

    res = JSON.parse(@response.body)
    assert res.key?("error")
    assert res["error"] == "You need to sign in or sign up before continuing."
  end

  def test_no_audit_log_for_anonymous_pushes
    Settings.enable_logins = true

    @luca = users(:luca)
    @luca.confirm

    # Create an anonymous push
    post passwords_path(format: :json), params: {password: {payload: "testpw", expire_after_views: 2}}, as: :json
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("url_token")
    url_token = res["url_token"]

    # Generate views on that push
    3.times do
      get "/p/#{url_token}.json"
      assert_response :success
    end

    # Get the Audit Log with a token
    get "/p/#{url_token}/audit.json", as: :json
    assert_response :unauthorized

    res = JSON.parse(@response.body)
    assert res.key?("error")
    assert res["error"] == "You need to sign in or sign up before continuing."
  end
end
