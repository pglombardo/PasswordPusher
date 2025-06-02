# frozen_string_literal: true

require "test_helper"
require "uri"

class QrJsonPreviewTest < ActionDispatch::IntegrationTest
  setup do
    Settings.enable_logins = true
    Settings.enable_qr_pushes = true
  end

  def test_preview_anonymous_response
    post json_pushes_path(format: :json), params: {password: {kind: "qr", payload: "testqr", expire_after_views: 2}}
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("url_token")

    get "/p/#{res["url_token"]}/preview.json"
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("url")
  end

  def test_authenticated_preview_response
    Settings.enable_logins = true

    @luca = users(:luca)
    @luca.confirm

    post json_pushes_path(format: :json), params: {password: {kind: "qr", payload: "testqr", expire_after_views: 2}},
      headers: {"X-User-Email": @luca.email,
                "X-User-Token": @luca.authentication_token}, as: :json
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("url_token")

    url_token = res["url_token"]

    get "/p/#{url_token}/preview.json",
      headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}, as: :json
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("url")
    uri = URI.parse(res["url"])
    assert_not (uri.path =~ /#{url_token}/).nil?
  end

  def test_override_base_url
    Settings.override_base_url = "https://example.com:12345"

    post json_pushes_path(format: :json), params: {password: {
      payload: "testqr",
      expire_after_views: 2
    }}

    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("url_token")

    get "/p/#{res["url_token"]}/preview.json"
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("url")

    uri = URI.parse(res["url"])
    assert uri.host == "example.com"
    assert uri.port == 12345
    assert uri.scheme == "https"
    assert_not (uri.path =~ /#{res["url_token"]}/).nil?
  end
end
