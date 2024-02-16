# frozen_string_literal: true

require "test_helper"
require "uri"

class PasswordJsonPreviewTest < ActionDispatch::IntegrationTest
  def test_preview_anonymous_response
    post passwords_path(format: :json), params: {password: {payload: "testpw", expire_after_views: 2}}
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

    post passwords_path(format: :json), params: {password: {payload: "testpw", expire_after_views: 2}},
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
end
