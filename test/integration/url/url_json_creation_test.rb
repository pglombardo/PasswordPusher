require 'test_helper'

class UrlJsonCreationTest < ActionDispatch::IntegrationTest
  def test_basic_json_creation
    post urls_path(format: :json), params: { url: { payload: 'https://the0x00.dev' } }
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?('payload') == false # No payload on create response
    assert res.key?('url_token')
    assert res.key?('expired')
    assert_equal false, res['expired']
    assert res.key?('deleted')
    assert_equal false, res['deleted']
    assert res.key?('deletable_by_viewer')
    assert_equal Settings.deletable_pushes_default, res['deletable_by_viewer']
    assert res.key?('days_remaining')
    assert_equal Settings.expire_after_days_default, res['days_remaining']
    assert res.key?('views_remaining')
    assert_equal Settings.expire_after_views_default, res['views_remaining']

    # These should be default values since we didn't specify them in the params
    assert res.key?('expire_after_days')
    assert_equal Settings.expire_after_days_default, res['expire_after_days']
    assert res.key?('expire_after_views')
    assert_equal Settings.expire_after_views_default, res['expire_after_views']
  end

  def test_custom_days_expiration
    post urls_path(format: :json), params: { url: { payload: 'https://the0x00.dev', expire_after_days: 1 } }
    assert_response :success

    res = JSON.parse(@response.body)

    assert res.key?('days_remaining')
    assert_equal 1, res['days_remaining']

    assert res.key?('expire_after_days')
    assert_equal 1, res['expire_after_days']
  end

  def test_custom_views_expiration
    post urls_path(format: :json), params: { url: { payload: 'https://the0x00.dev', expire_after_views: 5 } }
    assert_response :success

    res = JSON.parse(@response.body)

    assert res.key?('views_remaining')
    assert_equal 5, res['views_remaining']

    assert res.key?('expire_after_days')
    assert_equal 5, res['expire_after_views']
  end

  def test_bad_request
    post urls_path(format: :json), params: {}
    assert_response :bad_request

    res = JSON.parse(@response.body)
    assert_equal "No URL or note provided.", res["error"]
  end
end
