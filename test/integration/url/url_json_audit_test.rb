# frozen_string_literal: true

require "test_helper"

class UrlJsonAuditTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Settings.enable_logins = true
    Settings.enable_url_pushes = true
    Rails.application.reload_routes!
  end

  def test_audit_response_for_authenticated
    @luca = users(:luca)
    @luca.confirm

    # Create a push
    post urls_path(format: :json), params: {url: {payload: "https://the0x00.dev", expire_after_views: 2}},
      headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("url_token")
    url_token = res["url_token"]

    # Generate views on that push
    get "/r/#{url_token}.json"
    assert_response :success
    res = JSON.parse(@response.body)
    assert_equal "https://the0x00.dev", res["payload"]

    get "/r/#{url_token}.json"
    assert_response :success
    res = JSON.parse(@response.body)
    assert_equal "https://the0x00.dev", res["payload"]

    get "/r/#{url_token}.json"
    assert_response :success
    res = JSON.parse(@response.body)
    assert_nil res["payload"]

    # Get the Audit Log
    get "/r/#{url_token}/audit.json",
      headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}, as: :json
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("views")
    assert_equal 4, res["views"].length

    first_view = res["views"].first
    assert first_view.key?("ip")
    assert first_view.key?("user_agent")
    assert first_view.key?("referrer")
    assert first_view.key?("created_at")
    assert first_view.key?("updated_at")
    assert first_view.key?("kind")

    second_view = res["views"].second
    assert second_view.key?("ip")
    assert second_view.key?("user_agent")
    assert second_view.key?("referrer")
    assert second_view.key?("created_at")
    assert second_view.key?("updated_at")
    assert second_view.key?("kind")
    assert_equal res["views"].map { |view| view.except("created_at", "updated_at") }, [{"ip" => "127.0.0.1", "user_agent" => "", "referrer" => "", "kind" => "creation"}, {"ip" => "127.0.0.1", "user_agent" => "", "referrer" => "", "kind" => "view"}, {"ip" => "127.0.0.1", "user_agent" => "", "referrer" => "", "kind" => "view"}, {"ip" => "127.0.0.1", "user_agent" => "", "referrer" => "", "kind" => "failed_view"}]
  end

  def test_audit_response_for_created_expired_successful_and_unsuccessful_views
    @luca = users(:luca)
    @luca.confirm

    # Create a push
    post urls_path(format: :json), params: {url: {payload: "https://the0x00.dev", passphrase: "asdf", expire_after_views: 3}},
      headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("url_token")
    url_token = res["url_token"]

    # Generate views on that push
    2.times do
      get "/r/#{url_token}.json?passphrase=asdf"
      assert_response :success
    end

    # Generate unsuccessful views on that push because of wrong passphrase
    get "/r/#{url_token}.json"
    assert_response :unauthorized

    # Delete the new url via json e.g. /r/<url_token>.json
    delete "/r/#{res["url_token"]}.json",
      headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}
    assert_response :success

    # Generate views on that push
    2.times do
      get "/r/#{url_token}.json"
      assert_response :success
    end

    # Get the Audit Log
    get "/r/#{url_token}/audit.json",
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
    post urls_path(format: :json), params: {url: {payload: "https://the0x00.dev", expire_after_views: 2}},
      headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("url_token")
    url_token = res["url_token"]

    # Generate views on that push
    get "/r/#{url_token}.json"
    assert_response :success
    res = JSON.parse(@response.body)
    assert_equal "https://the0x00.dev", res["payload"]

    get "/r/#{url_token}.json"
    assert_response :success
    res = JSON.parse(@response.body)
    assert_equal "https://the0x00.dev", res["payload"]

    get "/r/#{url_token}.json"
    assert_response :success
    res = JSON.parse(@response.body)
    assert_nil res["payload"]

    # Get the Audit Log without a token
    get "/r/#{url_token}/audit.json", as: :json
    assert_response :unauthorized
  end
end
