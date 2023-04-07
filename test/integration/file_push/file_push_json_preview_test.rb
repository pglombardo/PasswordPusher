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
    }
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("url_token")

    get "/f/#{res['url_token']}/preview.json"
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("url")
  end

  def test_authenticated_preview_response
    Settings.enable_logins = true

    @luca = users(:luca)
    @luca.confirm

    post file_pushes_path(format: :json), params: {
      file_push: {
        payload: 'testpw',
        expire_after_views: 2,
        files: [
          fixture_file_upload('monkey.png', 'image/jpeg')
        ]
      }
    }

    post passwords_path(format: :json), params: { :password => { payload: "testpw", expire_after_views: 2 }}, headers: { 'X-User-Email': @luca.email, 'X-User-Token': @luca.authentication_token }, as: :json
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("url_token")

    url_token = res['url_token']

    get "/p/#{url_token}/preview.json", headers: { 'X-User-Email': @luca.email, 'X-User-Token': @luca.authentication_token }, as: :json
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("url")
    uri = URI.parse(res['url'])
    assert !(uri.path =~ /#{url_token}/).nil?
  end
end