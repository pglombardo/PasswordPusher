# frozen_string_literal: true

require "test_helper"

class UrlJsonDeletionTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Settings.enable_logins = true
    Settings.enable_url_pushes = true
    Rails.application.reload_routes!

    @luca = users(:luca)
    @luca.confirm
  end

  def test_deletion
    # Create url
    post urls_path(format: :json), params: {url: {payload: "https://the0x00.dev"}}, headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("payload") == false
    assert res.key?("url_token")
    assert res.key?("expired")
    assert_equal false, res["expired"]
    assert res.key?("deleted")
    assert_equal false, res["deleted"]
    assert res.key?("deletable_by_viewer")
    assert_nil res["deletable_by_viewer"]
    assert res.key?("days_remaining")
    assert_equal Settings.url.expire_after_days_default, res["days_remaining"]
    assert res.key?("views_remaining")
    assert_equal Settings.url.expire_after_views_default, res["views_remaining"]

    # Delete the new url via json e.g. /r/<url_token>.json
    delete "/r/#{res["url_token"]}.json",
      headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("payload") == false
    assert res.key?("url_token")
    assert res.key?("expired")
    assert_equal true, res["expired"]
    assert res.key?("expired_on")
    assert_not_nil res["expired_on"]
    assert res.key?("deleted")
    assert_equal true, res["deleted"]
    assert res.key?("deletable_by_viewer")
    assert_nil res["deletable_by_viewer"]

    assert_equal res.keys.sort, ["created_at", "days_remaining", "deletable_by_viewer", "deleted", "expire_after_days", "expire_after_views", "expired", "expired_on", "html_url", "json_url", "passphrase", "retrieval_step", "updated_at", "url_token", "views_remaining"].sort
    assert_equal res.except("url_token", "created_at", "updated_at", "expired_on", "html_url", "json_url"), {"expire_after_views" => 5,
      "expired" => true,
      "retrieval_step" => false,
      "passphrase" => nil,
      "expire_after_days" => 7,
      "days_remaining" => 7,
      "views_remaining" => 5,
      "deleted" => true,
      "deletable_by_viewer" => nil}

    assert res.key?("days_remaining")
    assert_equal Settings.url.expire_after_days_default, res["days_remaining"]
    assert res.key?("views_remaining")
    assert_equal Settings.url.expire_after_views_default, res["views_remaining"]

    # Now try to retrieve the url again
    get "/r/#{res["url_token"]}.json"
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("payload")
    assert_nil res["payload"]
    assert res.key?("url_token")
    assert res.key?("expired")
    assert_equal true, res["expired"]
    assert res.key?("deleted")
    assert_equal true, res["deleted"]
    assert res.key?("deletable_by_viewer")
    assert_nil res["deletable_by_viewer"]
    assert res.key?("days_remaining")
    assert_equal Settings.url.expire_after_days_default, res["days_remaining"]
    assert res.key?("views_remaining")
    assert_equal Settings.url.expire_after_views_default - 1, res["views_remaining"]
  end
end
