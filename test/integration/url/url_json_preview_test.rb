require 'test_helper'
require 'uri'

class UrlJsonPreviewTest < ActionDispatch::IntegrationTest
  def test_preview_anonymous_response
    post urls_path(format: :json), params: { :url => { payload: "https://the0x00.dev", expire_after_views: 2 }}
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("url_token")
    
    get "/r/#{res['url_token']}/preview.json"
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("url")
  end
  
  def test_authenticated_preview_response
    Settings.enable_logins = true

    @luca = users(:luca)
    @luca.confirm

    post urls_path(format: :json), params: { :url => { payload: "https://the0x00.dev", expire_after_views: 2 }}, headers: { 'X-User-Email': @luca.email, 'X-User-Token': @luca.authentication_token }, as: :json
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("url_token")

    url_token = res['url_token']
    
    get "/r/#{url_token}/preview.json", headers: { 'X-User-Email': @luca.email, 'X-User-Token': @luca.authentication_token }, as: :json
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("url")
    uri = URI.parse(res['url'])
    assert !(uri.path =~ /#{url_token}/).nil?
  end
end