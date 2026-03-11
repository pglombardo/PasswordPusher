# frozen_string_literal: true

require "test_helper"
require "uri"

class UrlJsonPreviewTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Settings.enable_url_pushes = true
    Rails.application.reload_routes!

    @luca = users(:luca)
  end

  def test_authenticated_preview_response
    @luca = users(:luca)
    post urls_path(format: :json), params: {url: {payload: "https://the0x00.dev", expire_after_views: 2}},
      headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}, as: :json
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("url_token")

    url_token = res["url_token"]

    get "/r/#{url_token}/preview.json",
      headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}, as: :json
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("url")
    uri = URI.parse(res["url"])
    assert_not (uri.path =~ /#{url_token}/).nil?
  end
end
