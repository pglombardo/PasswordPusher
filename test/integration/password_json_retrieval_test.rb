require 'test_helper'

class PasswordJsonRetrievalTest < ActionDispatch::IntegrationTest
  def test_view_expiration
    post "/p.json", params: { :password => { payload: "testpw", expire_after_views: 2 }}
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("payload")
    assert_equal "testpw", res["payload"]
    assert res.key?("url_token")
    assert res.key?("expired")
    assert_equal false, res["expired"]
    assert res.key?("deleted")
    assert_equal false, res["deleted"]
    assert res.key?("deletable_by_viewer")
    assert_equal DELETABLE_PASSWORDS_DEFAULT, res["deletable_by_viewer"]
    assert res.key?("days_remaining")
    assert_equal 2, res["views_remaining"]
    assert res.key?("expire_after_days")
    assert_equal 2, res['expire_after_views']

    # Now try to retrieve the password for the first time
    get "/p/" + res["url_token"] + ".json"
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("expired")
    assert_equal false, res["expired"]
    assert res.key?("deleted")
    assert_equal false, res["deleted"]
    assert res.key?("payload")
    assert_equal "testpw", res["payload"]
    assert res.key?("views_remaining")
    assert_equal 1, res["views_remaining"]
    assert res.key?("expire_after_views")
    assert_equal 2, res['expire_after_views']

    # ...and the second view
    get "/p/" + res["url_token"] + ".json"
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("expired")
    assert_equal false, res["expired"]
    assert res.key?("deleted")
    assert_equal false, res["deleted"]
    assert res.key?("payload")
    assert_equal "testpw", res["payload"]
    assert res.key?("views_remaining")
    assert_equal 0, res["views_remaining"]
    assert res.key?("expire_after_views")
    assert_equal 2, res['expire_after_views']

    # With the third view, we should have an expired password
    get "/p/" + res["url_token"] + ".json"
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("expired")
    assert_equal true, res["expired"]
    assert res.key?("deleted")
    assert_equal false, res["deleted"]
    assert res.key?("payload")
    assert_nil res["payload"]
    assert res.key?("views_remaining")
    assert_equal 0, res["views_remaining"]
    assert res.key?("expire_after_views")
    assert_equal 2, res['expire_after_views']
  end
end
