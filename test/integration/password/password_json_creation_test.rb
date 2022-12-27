require 'test_helper'

class PasswordJsonCreationTest < ActionDispatch::IntegrationTest
  def test_basic_json_creation
    post '/p.json', params: { password: { payload: 'testpw' } }
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

  def test_json_creation_with_uncommon_characters
    post '/p.json', params: { password: { payload: '£¬' } }
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

    # Validate payload
    get "/p/#{res["url_token"]}.json"
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?('payload')
    assert_equal '£¬', res['payload']
  end

  def test_deletable_by_viewer
    post '/p.json', params: { password: { payload: 'testpw', deletable_by_viewer: 'true' } }
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?('deletable_by_viewer')
    assert_equal true, res['deletable_by_viewer']
  end

  def test_not_deletable_by_viewer
    post '/p.json', params: { password: { payload: 'testpw', deletable_by_viewer: 'false' } }
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?('deletable_by_viewer')
    assert_equal false, res['deletable_by_viewer']
  end

  def test_deletable_by_viewer_absent_is_default
    post '/p.json', params: { password: { payload: 'testpw' } }
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?('deletable_by_viewer')
    assert_equal Settings.enable_deletable_pushes, res['deletable_by_viewer']
  end

  def test_custom_days_expiration
    post '/p.json', params: { password: { payload: 'testpw', expire_after_days: 1 } }
    assert_response :success

    res = JSON.parse(@response.body)

    assert res.key?('days_remaining')
    assert_equal 1, res['days_remaining']

    assert res.key?('expire_after_days')
    assert_equal 1, res['expire_after_days']
  end

  def test_custom_views_expiration
    post '/p.json', params: { password: { payload: 'testpw', expire_after_views: 5 } }
    assert_response :success

    res = JSON.parse(@response.body)

    assert res.key?('views_remaining')
    assert_equal 5, res['views_remaining']

    assert res.key?('expire_after_days')
    assert_equal 5, res['expire_after_views']
  end

  def test_bad_request
    post '/p.json', params: {}
    assert_response :bad_request

    res = JSON.parse(@response.body)
    assert res == {"error"=>"No password, text or files provided.  Try again."}
  end
end
