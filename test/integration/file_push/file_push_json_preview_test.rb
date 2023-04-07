require 'test_helper'
require 'uri'

class FilePushJsonPreviewTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Settings.enable_logins = true
    Settings.enable_file_pushes = true
    Rails.application.reload_routes!
    @luca = users(:luca)
    @luca.confirm
  end

  teardown do
  end

  def test_preview_response
    post file_pushes_path(format: :json), params: {
      file_push: {
        payload: 'testpw',
        expire_after_views: 2,
        files: [
          fixture_file_upload('monkey.png', 'image/jpeg')
        ]
      }
    },
    headers: { 'X-User-Email': @luca.email, 'X-User-Token': @luca.authentication_token }
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("url_token")

    get preview_file_push_path(res['url_token'], format: :json), headers: { 'X-User-Email': @luca.email, 'X-User-Token': @luca.authentication_token }
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("url")
  end

  def test_authenticated_preview_response
    post file_pushes_path(format: :json), params: {
      file_push: {
        payload: 'testpw',
        expire_after_views: 2,
        files: [
          fixture_file_upload('monkey.png', 'image/jpeg')
        ]
      }
    },
    headers: { 'X-User-Email': @luca.email, 'X-User-Token': @luca.authentication_token }
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("url_token")

    url_token = res['url_token']

    get preview_file_push_path(url_token, format: :json), headers: { 'X-User-Email': @luca.email, 'X-User-Token': @luca.authentication_token }, as: :json
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("url")
    uri = URI.parse(res['url'])
    assert !(uri.path =~ /#{url_token}/).nil?
  end
end