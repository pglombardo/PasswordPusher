# frozen_string_literal: true

require "test_helper"

class QrJsonAuditTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Settings.enable_logins = true
    Settings.enable_qr_pushes = true
  end

  def test_audit_response_for_authenticated
    Settings.enable_logins = true

    @luca = users(:luca)
    @luca.confirm

    # Create a push
    post json_pushes_path(format: :json), params: {password: {kind: "qr", payload: "testqr", expire_after_views: 2}},
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
    assert_equal res["views"].length, 4

    first_view = res["views"].first
    assert first_view.key?("ip")
    assert first_view.key?("user_agent")
    assert first_view.key?("referrer")
    assert first_view.key?("created_at")
    assert first_view.key?("updated_at")
    assert first_view.key?("kind")
    assert_equal res["views"].map { |view| view.except("created_at", "updated_at") }, [{"ip" => "127.0.0.1", "user_agent" => "", "referrer" => "", "kind" => "creation"}, {"ip" => "127.0.0.1", "user_agent" => "", "referrer" => "", "kind" => "view"}, {"ip" => "127.0.0.1", "user_agent" => "", "referrer" => "", "kind" => "view"}, {"ip" => "127.0.0.1", "user_agent" => "", "referrer" => "", "kind" => "failed_view"}]
  end

  def test_audit_response_for_created_expired_successful_and_unsuccessful_views
    Settings.enable_logins = true

    @luca = users(:luca)
    @luca.confirm

    # Create a push
    post json_pushes_path(format: :json), params: {password: {kind: "qr", payload: "testqr", passphrase: "asdf", expire_after_views: 3}},
      headers: {"X-User-Email": @luca.email,
                "X-User-Token": @luca.authentication_token}, as: :json
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("url_token")
    url_token = res["url_token"]

    # Generate views on that push
    2.times do
      get "/p/#{url_token}.json?passphrase=asdf"
      assert_response :success
    end

    # Generate unsuccessful views on that push because of wrong passphrase
    get "/p/#{url_token}.json"
    assert_response :unauthorized

    delete json_push_path(url_token, format: :json),
      headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}, as: :json
    assert_response :success

    # Generate views on that push
    2.times do
      get "/p/#{url_token}.json"
      assert_response :success
    end

    # Get the Audit Log
    get "/p/#{url_token}/audit.json",
      headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}, as: :json
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("views")
    assert_equal res["views"].length, 7

    first_view = res["views"].first
    assert first_view.key?("ip")
    assert first_view.key?("user_agent")
    assert first_view.key?("referrer")
    assert first_view.key?("created_at")
    assert first_view.key?("updated_at")
    assert first_view.key?("kind")
    assert_equal res["views"].map { |view| view.except("created_at", "updated_at") }, [{"ip" => "127.0.0.1", "user_agent" => "", "referrer" => "", "kind" => "creation"}, {"ip" => "127.0.0.1", "user_agent" => "", "referrer" => "", "kind" => "view"}, {"ip" => "127.0.0.1", "user_agent" => "", "referrer" => "", "kind" => "view"}, {"ip" => "127.0.0.1", "user_agent" => "", "referrer" => "", "kind" => "failed_passphrase"}, {"ip" => "127.0.0.1", "user_agent" => "", "referrer" => "", "kind" => "expire"}, {"ip" => "127.0.0.1", "user_agent" => "", "referrer" => "", "kind" => "failed_view"}, {"ip" => "127.0.0.1", "user_agent" => "", "referrer" => "", "kind" => "failed_view"}]
  end

  def test_no_token_no_audit_log
    Settings.enable_logins = true

    @luca = users(:luca)
    @luca.confirm

    # Create a push
    post json_pushes_path(format: :json), params: {password: {kind: "qr", payload: "testqr", expire_after_views: 2}},
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
  end

  def test_no_audit_log_for_anonymous_pushes
    Settings.enable_logins = true

    @luca = users(:luca)
    @luca.confirm

    # Create an anonymous push
    post json_pushes_path(format: :json), params: {password: {kind: "qr", payload: "testqr", expire_after_views: 2}}, as: :json
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
  end
end
