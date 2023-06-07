require 'test_helper'

class PasswordJsonRetrievalTest < ActionDispatch::IntegrationTest
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

  def test_view_expiration
    # Create a push with two views
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
    assert res.key?("payload") == false # No payload on create response
    assert res.key?("url_token")
    assert res.key?("expired")
    assert_equal false, res["expired"]
    assert res.key?("deleted")
    assert_equal false, res["deleted"]
    assert res.key?("deletable_by_viewer")
    assert_equal Settings.files.deletable_pushes_default, res["deletable_by_viewer"]
    assert res.key?("days_remaining")
    assert_equal 2, res["views_remaining"]
    assert res.key?("expire_after_days")
    assert_equal 2, res['expire_after_views']

    # Now try to retrieve the push for the first time
    get file_push_path(res["url_token"], format: :json)
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
    get file_push_path(res["url_token"], format: :json)
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

    # With the third view, we should have an expired push
    get file_push_path(res["url_token"], format: :json)
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
