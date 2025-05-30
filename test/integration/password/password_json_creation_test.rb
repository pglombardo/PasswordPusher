# frozen_string_literal: true

require "test_helper"

class PasswordJsonCreationTest < ActionDispatch::IntegrationTest
  def test_basic_json_creation
    post passwords_path(format: :json), params: {password: {payload: "testpw"}}
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("payload") == false # No payload on create response
    assert res.key?("url_token")
    assert res.key?("name")
    assert_equal "", res["name"]
    assert res.key?("expired")
    assert_equal false, res["expired"]
    assert res.key?("deleted")
    assert_equal false, res["deleted"]
    assert res.key?("deletable_by_viewer")
    assert_equal res.keys.sort, ["created_at", "days_remaining", "deletable_by_viewer", "deleted", "expire_after_days", "expire_after_views", "expired", "expired_on", "html_url", "json_url", "name", "note", "passphrase", "retrieval_step", "updated_at", "url_token", "views_remaining"].sort
    assert_equal res.except("url_token", "created_at", "updated_at", "html_url", "json_url"), {"expire_after_views" => 5,
      "expired" => false,
      "retrieval_step" => false,
      "expired_on" => nil,
      "passphrase" => "",
      "expire_after_days" => 7,
      "days_remaining" => 7,
      "views_remaining" => 5,
      "deleted" => false,
      "deletable_by_viewer" => true,
      "note" => "",
      "name" => ""}

    assert_equal Settings.pw.deletable_pushes_default, res["deletable_by_viewer"]
    assert res.key?("days_remaining")
    assert_equal Settings.pw.expire_after_days_default, res["days_remaining"]
    assert res.key?("views_remaining")
    assert_equal Settings.pw.expire_after_views_default, res["views_remaining"]

    # These should be default values since we didn't specify them in the params
    assert res.key?("expire_after_days")
    assert_equal Settings.pw.expire_after_days_default, res["expire_after_days"]
    assert res.key?("expire_after_views")
    assert_equal Settings.pw.expire_after_views_default, res["expire_after_views"]
  end

  def test_json_creation_with_uncommon_characters
    post passwords_path(format: :json), params: {password: {payload: "£¬"}}
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("payload") == false # No payload on create response
    assert res.key?("url_token")
    assert res.key?("expired")
    assert_equal false, res["expired"]
    assert res.key?("deleted")
    assert_equal false, res["deleted"]
    assert res.key?("deletable_by_viewer")
    assert_equal Settings.pw.deletable_pushes_default, res["deletable_by_viewer"]
    assert res.key?("days_remaining")
    assert_equal Settings.pw.expire_after_days_default, res["days_remaining"]
    assert res.key?("views_remaining")
    assert_equal Settings.pw.expire_after_views_default, res["views_remaining"]

    # These should be default values since we didn't specify them in the params
    assert res.key?("expire_after_days")
    assert_equal Settings.pw.expire_after_days_default, res["expire_after_days"]
    assert res.key?("expire_after_views")
    assert_equal Settings.pw.expire_after_views_default, res["expire_after_views"]

    # Validate payload
    get "/p/#{res["url_token"]}.json"
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("payload")
    assert_equal "£¬", res["payload"]
  end

  def test_deletable_by_viewer
    post passwords_path(format: :json), params: {password: {payload: "testpw", deletable_by_viewer: "true"}}
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("deletable_by_viewer")
    assert_equal true, res["deletable_by_viewer"]
  end

  def test_not_deletable_by_viewer
    post passwords_path(format: :json), params: {password: {payload: "testpw", deletable_by_viewer: "false"}}
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("deletable_by_viewer")
    assert_equal false, res["deletable_by_viewer"]
  end

  def test_deletable_by_viewer_absent_is_default
    post passwords_path(format: :json), params: {password: {payload: "testpw"}}
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("deletable_by_viewer")
    assert_equal Settings.pw.enable_deletable_pushes, res["deletable_by_viewer"]
  end

  def test_custom_days_expiration
    post passwords_path(format: :json), params: {password: {payload: "testpw", expire_after_days: 1}}
    assert_response :success

    res = JSON.parse(@response.body)

    assert res.key?("days_remaining")
    assert_equal 1, res["days_remaining"]

    assert res.key?("expire_after_days")
    assert_equal 1, res["expire_after_days"]
  end

  def test_custom_views_expiration
    post passwords_path(format: :json), params: {password: {payload: "testpw", expire_after_views: 5}}
    assert_response :success

    res = JSON.parse(@response.body)

    assert res.key?("views_remaining")
    assert_equal 5, res["views_remaining"]

    assert res.key?("expire_after_days")
    assert_equal 5, res["expire_after_views"]
  end

  def test_creation_with_kind_on_endpoint_starting_with_p
    post json_pushes_path(format: :json), params: {password: {kind: "text", payload: "testpw"}}
    assert_response :success

    res = JSON.parse(@response.body)
    url_token = res["url_token"]
    push = Push.find_by(url_token:)
    assert_equal push.kind, "text"
  end

  def test_bad_request
    post passwords_path(format: :json), params: {}
    assert_response :bad_request

    res = JSON.parse(@response.body)
    assert res == {"error" => "param is missing or the value is empty: password"}
  end
end
