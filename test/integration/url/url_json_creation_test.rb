require 'test_helper'

class UrlJsonCreationTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Settings.enable_logins = true
    Settings.enable_url_pushes = true
    Rails.application.reload_routes!

    @luca = users(:luca)
    @luca.confirm
  end

  teardown do
  end

  def test_basic_json_creation
    post urls_path(format: :json), params: { url: { payload: 'https://the0x00.dev' } }, headers: { 'X-User-Email': @luca.email, 'X-User-Token': @luca.authentication_token }
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?('payload') == false # No payload on create response
    assert res.key?('url_token')
    assert res.key?('expired')
    assert_equal false, res['expired']
    assert res.key?('deleted')
    assert_equal false, res['deleted']
    assert !res.key?('deletable_by_viewer')
    assert res.key?('days_remaining')
    assert_equal Settings.url.expire_after_days_default, res['days_remaining']
    assert res.key?('views_remaining')
    assert_equal Settings.url.expire_after_views_default, res['views_remaining']

    # These should be default values since we didn't specify them in the params
    assert res.key?('expire_after_days')
    assert_equal Settings.url.expire_after_days_default, res['expire_after_days']
    assert res.key?('expire_after_views')
    assert_equal Settings.url.expire_after_views_default, res['expire_after_views']
  end

  def test_custom_days_expiration
    post urls_path(format: :json), params: { url: { payload: 'https://the0x00.dev', expire_after_days: 1 } }, headers: { 'X-User-Email': @luca.email, 'X-User-Token': @luca.authentication_token }
    assert_response :success

    res = JSON.parse(@response.body)

    assert res.key?('days_remaining')
    assert_equal 1, res['days_remaining']

    assert res.key?('expire_after_days')
    assert_equal 1, res['expire_after_days']
  end

  def test_custom_views_expiration
    post urls_path(format: :json), params: { url: { payload: 'https://the0x00.dev', expire_after_views: 5 } }, headers: { 'X-User-Email': @luca.email, 'X-User-Token': @luca.authentication_token }
    assert_response :success

    res = JSON.parse(@response.body)

    assert res.key?('views_remaining')
    assert_equal 5, res['views_remaining']

    assert res.key?('expire_after_days')
    assert_equal 5, res['expire_after_views']
  end

  def test_bad_request
    post urls_path(format: :json), params: {}, headers: { 'X-User-Email': @luca.email, 'X-User-Token': @luca.authentication_token }
    assert_response :unprocessable_entity

    res = JSON.parse(@response.body)
    assert_equal "No URL or note provided.", res["error"]
  end
end
