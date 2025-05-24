# frozen_string_literal: true

require "test_helper"

class PasswordJsonDeletionTest < ActionDispatch::IntegrationTest
  def test_deletion
    # Create password
    post passwords_path(format: :json), params: {password: {payload: "testpw"}}
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("payload") == false
    assert res.key?("url_token")
    assert res.key?("expired")
    assert_equal false, res["expired"]
    assert res.key?("deleted")
    assert_equal false, res["deleted"]
    assert res.key?("deletable_by_viewer")
    assert_equal Settings.pw.deletable_pushes_default, res["deletable_by_viewer"]
    assert res.key?("days_remaining")
    assert_equal Settings.pw.expire_after_days_default, res["days_remaining"]
    assert res.key?("views_remaining")
    assert_equal Settings.pw.expire_after_views_default, res["views_remaining"]

    # Delete the new password via json e.g. /p/<url_token>.json
    delete "/p/#{res["url_token"]}.json"
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("payload") == false
    assert res.key?("url_token")
    assert res.key?("expired")
    assert_equal true, res["expired"]
    assert res.key?("expired_on")
    assert_not_nil res["expired_on"]
    assert res.key?("deleted")
    assert_equal true, res["deleted"]
    assert_equal res.keys.sort, ["expired", "deleted", "expired_on", "expire_after_days", "expire_after_views", "url_token", "created_at", "updated_at", "deletable_by_viewer", "retrieval_step", "days_remaining", "views_remaining"].sort
    assert_equal res.except("url_token", "created_at", "updated_at", "expired_on"), {"expired" => true,
      "deleted" => true,
      "expire_after_days" => 7,
      "expire_after_views" => 5,
      "deletable_by_viewer" => true,
      "retrieval_step" => false,
      "days_remaining" => 7,
      "views_remaining" => 5}
    assert res.key?("deletable_by_viewer")
    assert_equal Settings.pw.deletable_pushes_default, res["deletable_by_viewer"]
    assert res.key?("days_remaining")
    assert_equal Settings.pw.expire_after_days_default, res["days_remaining"]
    assert res.key?("views_remaining")
    assert_equal Settings.pw.expire_after_views_default, res["views_remaining"]

    # Now try to retrieve the password again
    get "/p/#{res["url_token"]}.json"
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("payload")
    assert_nil res["payload"]
    assert res.key?("url_token")
    assert res.key?("expired")
    assert_equal true, res["expired"]
    assert res.key?("deleted")
    assert_equal true, res["deleted"]
    assert res.key?("deletable_by_viewer")
    assert_equal Settings.pw.deletable_pushes_default, res["deletable_by_viewer"]
    assert res.key?("days_remaining")
    assert_equal Settings.pw.expire_after_days_default, res["days_remaining"]
    assert res.key?("views_remaining")
    assert_equal Settings.pw.expire_after_views_default - 1, res["views_remaining"]
  end
end
