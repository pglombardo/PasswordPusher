# frozen_string_literal: true

require "test_helper"

class UrlJsonRetrievalTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Settings.enable_logins = true
    Settings.enable_url_pushes = true
    Rails.application.reload_routes!

    @luca = users(:luca)
    @luca.confirm
  end

  def test_view_expiration
    post urls_path(format: :json), params: {url: {payload: "https://the0x00.dev", expire_after_views: 2}}, headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}
    assert_response :success

    # Push a url with two views
    res = JSON.parse(@response.body)
    assert res.key?("payload") == false # No payload on create response
    assert res.key?("url_token")
    assert res.key?("expired")
    assert_equal false, res["expired"]
    assert res.key?("deleted")
    assert_equal false, res["deleted"]
    assert_not res.key?("deletable_by_viewer")
    assert res.key?("days_remaining")
    assert_equal 2, res["views_remaining"]
    assert res.key?("expire_after_days")
    assert_equal 2, res["expire_after_views"]

    # Now try to retrieve the url for the first time
    get "/r/#{res["url_token"]}.json",
      headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("expired")
    assert_equal false, res["expired"]
    assert res.key?("deleted")
    assert_equal false, res["deleted"]
    assert res.key?("payload")
    assert_equal "https://the0x00.dev", res["payload"]
    assert res.key?("views_remaining")
    assert_equal 1, res["views_remaining"]
    assert res.key?("expire_after_views")
    assert_equal 2, res["expire_after_views"]

    # ...and the second view
    get "/r/#{res["url_token"]}.json",
      headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("expired")
    assert_equal false, res["expired"]
    assert res.key?("deleted")
    assert_equal false, res["deleted"]
    assert res.key?("payload")
    assert_equal "https://the0x00.dev", res["payload"]
    assert res.key?("views_remaining")
    assert_equal 0, res["views_remaining"]
    assert res.key?("expire_after_views")
    assert_equal 2, res["expire_after_views"]

    # Check the record directly; it should be expired after the last view
    url = Url.find_by!(url_token: res["url_token"])
    assert url.expired
    assert_nil url.payload
    assert_equal 0, url.views_remaining

    # With the third view, we should have an expired url
    get "/r/#{res["url_token"]}.json",
      headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("expired")
    assert_equal true, res["expired"]
    assert res.key?("deleted")
    assert_equal false, res["deleted"]
    assert res.key?("payload")
    assert_nil res["payload"]
    assert res.key?("views_remaining")
    assert_equal 0, res["views_remaining"]
    assert res.key?("expire_after_views")
    assert_equal 2, res["expire_after_views"]
  end
end
