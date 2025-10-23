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
    post passwords_path(format: :json), params: {password: {payload: "testpw", passphrase: "asdf", expire_after_views: 3}},
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

    delete password_path(url_token, format: :json),
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
  end

  def test_audit_pagination
    Settings.enable_logins = true

    @luca = users(:luca)
    @luca.confirm

    # Create a push
    post passwords_path(format: :json), params: {password: {payload: "testpw", expire_after_views: 100}},
      headers: {"X-User-Email": @luca.email,
                "X-User-Token": @luca.authentication_token}, as: :json
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("url_token")
    url_token = res["url_token"]

    # Generate 60 views to test pagination
    60.times do |i|
      get "/p/#{url_token}.json"
      assert_response :success
    end

    # Test first page (should return 50 results)
    get "/p/#{url_token}/audit.json?page=1",
      headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}, as: :json
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("views")
    assert_equal 50, res["views"].count, "First page should return exactly 50 results"

    # Verify all results have required fields
    res["views"].each do |view|
      assert view.key?("ip"), "Each result should have an ip"
      assert view.key?("user_agent"), "Each result should have a user_agent"
      assert view.key?("referrer"), "Each result should have a referrer"
      assert view.key?("created_at"), "Each result should have a created_at"
      assert view.key?("kind"), "Each result should have a kind"
    end

    # Test second page (should return remaining results)
    get "/p/#{url_token}/audit.json?page=2",
      headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}, as: :json
    assert_response :success

    res_page2 = JSON.parse(@response.body)
    assert res_page2["views"].count <= 50, "Second page should return at most 50 results"
    assert res_page2["views"].count > 0, "Second page should have some results"

    # Verify no overlap between pages
    first_page_tokens = res["views"].map { |view| view["created_at"] }
    second_page_tokens = res_page2["views"].map { |view| view["created_at"] }
    assert_empty first_page_tokens & second_page_tokens, "Pages should not have overlapping results"

    # Test third page (should return empty or remaining results)
    get "/p/#{url_token}/audit.json?page=3",
      headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}, as: :json
    assert_response :success

    res_page3 = JSON.parse(@response.body)
    assert res_page3["views"].count <= 50, "Third page should return at most 50 results"
  end

  def test_audit_pagination_invalid_page
    Settings.enable_logins = true

    @luca = users(:luca)
    @luca.confirm

    # Create a push
    post passwords_path(format: :json), params: {password: {payload: "testpw", expire_after_views: 2}},
      headers: {"X-User-Email": @luca.email,
                "X-User-Token": @luca.authentication_token}, as: :json
    assert_response :success

    res = JSON.parse(@response.body)
    url_token = res["url_token"]

    # Test invalid page parameter
    get "/p/#{url_token}/audit.json?page=invalid",
      headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}, as: :json
    assert_response :bad_request

    res = JSON.parse(@response.body)
    assert res.key?("error")
    assert_equal "Invalid page parameter", res["error"]

    # Test page parameter too high
    get "/p/#{url_token}/audit.json?page=201",
      headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}, as: :json
    assert_response :bad_request

    res = JSON.parse(@response.body)
    assert res.key?("error")
    assert_equal "Invalid page parameter", res["error"]

    # Test page parameter zero (should be converted to 1)
    get "/p/#{url_token}/audit.json?page=0",
      headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}, as: :json
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("views")
    # page=0 should be converted to page=1, so this should work
  end
end
