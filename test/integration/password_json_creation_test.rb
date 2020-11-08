require 'test_helper'

class PasswordJsonCreationTest < ActionDispatch::IntegrationTest
  def test_basic_json_creation
    post '/p.json', params: { :password => { payload: 'testpw' } }
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?('id')
    assert res.key?('payload')
    assert_equal 'testpw', res['payload']
    assert res.key?('url_token')
    assert res.key?('first_view')
    assert_equal true, res['first_view']
    assert res.key?('expired')
    assert_equal false, res['expired']
    assert res.key?('deleted')
    assert_equal false, res['deleted']
    assert res.key?('deletable_by_viewer')
    assert_equal DELETABLE_BY_VIEWER_DEFAULT, res['deletable_by_viewer']
    assert res.key?('days_remaining')
    assert_equal EXPIRE_AFTER_DAYS_DEFAULT, res['days_remaining']
    assert res.key?('views_remaining')
    assert_equal EXPIRE_AFTER_VIEWS_DEFAULT, res['views_remaining']

    # These should be default values since we didn't specify them in the params
    assert res.key?('expire_after_days')
    assert_equal EXPIRE_AFTER_DAYS_DEFAULT, res['expire_after_days']
    assert res.key?('expire_after_views')
    assert_equal EXPIRE_AFTER_VIEWS_DEFAULT, res['expire_after_views']
  end

  def test_deletable_by_viewer
    post '/p.json', params: { :password => { payload: 'testpw', deletable_by_viewer: 'true' } }
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?('id')
    assert res.key?('deletable_by_viewer')
    assert_equal true, res['deletable_by_viewer']
  end

  def test_not_deletable_by_viewer
    post '/p.json', params: { :password => { payload: 'testpw', deletable_by_viewer: 'false' } }
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?('id')
    assert res.key?('deletable_by_viewer')
    assert_equal false, res['deletable_by_viewer']
  end

  def test_custom_days_expiration
    post '/p.json', params: { :password => { payload: 'testpw', expire_after_days: 1 } }
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?('id')

    assert res.key?('days_remaining')
    assert_equal 1, res['days_remaining']

    assert res.key?('expire_after_days')
    assert_equal 1, res['expire_after_days']
  end

  def test_custom_views_expiration
    post '/p.json', params: { :password => { payload: 'testpw', expire_after_views: 5 } }
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?('id')

    assert res.key?('views_remaining')
    assert_equal 5, res['views_remaining']

    assert res.key?('expire_after_days')
    assert_equal 5, res['expire_after_views']
  end

  def test_free_first_view
    post '/p.json', params: { :password => { payload: 'testpw', first_view: true } }
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?('id')
    assert res.key?('first_view')
    assert_equal true, res['first_view']
  end

  def test_no_free_first_view
    post '/p.json', params: { :password => { payload: 'testpw', first_view: false } }
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?('id')
    assert res.key?('first_view')
    assert_equal false, res['first_view']
  end
end
