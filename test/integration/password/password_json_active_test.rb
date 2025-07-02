# frozen_string_literal: true

require "test_helper"

class PasswordJsonExpiredTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Settings.enable_logins = true
    Rails.application.reload_routes!

    @luca = users(:luca)
    @luca.confirm
  end

  def test_basic_json_expired
    post passwords_path(format: :json),
      params: {password: {payload: "testpw", name: "Test Password", note: "This is a test password"}},
      headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}
    assert_response :success

    get active_passwords_path(format: :json), headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}
    assert_response :success

    res = JSON.parse(@response.body)
    first_res = res.first
    assert_not first_res.key?("payload")
    assert first_res.key?("url_token")
    assert first_res.key?("name")
    assert_equal "Test Password", first_res["name"]
    assert first_res.key?("note")
    assert_equal "This is a test password", first_res["note"]
    assert first_res.key?("expired")
    assert_equal false, first_res["expired"]
    assert first_res.key?("expired_on")
    assert first_res.key?("deleted")
    assert_equal false, first_res["deleted"]
    assert first_res.key?("deletable_by_viewer")
    assert_equal first_res.keys.sort, ["created_at", "days_remaining", "deletable_by_viewer", "deleted", "expire_after_days", "expire_after_views", "expired", "expired_on", "html_url", "json_url", "name", "note", "passphrase", "retrieval_step", "updated_at", "url_token", "views_remaining"].sort
    assert_equal first_res.except("url_token", "created_at", "updated_at", "html_url", "json_url", "expired_on"), {"expire_after_views" => 5,
      "expired" => false,
      "deletable_by_viewer" => true,
      "retrieval_step" => false,
      "passphrase" => "",
      "expire_after_days" => 7,
      "days_remaining" => 7,
      "views_remaining" => 5,
      "deleted" => false,
      "note" => "This is a test password",
      "name" => "Test Password"}

    # These should be default values since we didn't specify them in the params
    assert_equal Settings.pw.deletable_pushes_default, first_res["deletable_by_viewer"]
    assert first_res.key?("days_remaining")
    assert_equal Settings.pw.expire_after_days_default, first_res["days_remaining"]
    assert first_res.key?("views_remaining")
    assert_equal Settings.pw.expire_after_views_default, first_res["views_remaining"]
    assert first_res.key?("expire_after_days")
    assert_equal Settings.pw.expire_after_days_default, first_res["expire_after_days"]
    assert first_res.key?("expire_after_views")
    assert_equal Settings.pw.expire_after_views_default, first_res["expire_after_views"]
  end
end
