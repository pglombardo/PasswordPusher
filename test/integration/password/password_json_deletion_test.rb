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
    assert_equal res.keys.sort, ["created_at", "days_remaining", "deletable_by_viewer", "deleted", "expire_after_days", "expire_after_views", "expired", "expired_on", "html_url", "json_url", "passphrase", "retrieval_step", "updated_at", "url_token", "views_remaining"].sort
    assert_equal res.except("url_token", "created_at", "updated_at", "expired_on", "html_url", "json_url"), {"expire_after_views" => 5,
      "expired" => true,
      "deletable_by_viewer" => true,
      "retrieval_step" => true,
      "passphrase" => nil,
      "expire_after_days" => 7,
      "days_remaining" => 7,
      "views_remaining" => 5,
      "deleted" => true}

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

  def test_anonymous_push_not_deletable_by_viewer_cannot_be_deleted_unauthenticated
    post passwords_path(format: :json), params: {
      password: {
        payload: "SUPER-SECRET",
        passphrase: "s3cr3t",
        deletable_by_viewer: "false"
      }
    }
    assert_response :success

    res = JSON.parse(@response.body)
    token = res["url_token"]
    assert_equal false, res["deletable_by_viewer"]
    push = Push.find_by!(url_token: token)
    assert_nil push.user_id

    # Passphrase still blocks reading
    get "/p/#{token}.json"
    assert_response :unauthorized

    # Unauthenticated DELETE must not destroy the push
    delete "/p/#{token}.json"
    assert_response :unauthorized
    assert_not push.reload.expired?
    assert_equal "SUPER-SECRET", push.payload

    # Intended recipient can still retrieve with passphrase
    get "/p/#{token}.json", params: {passphrase: "s3cr3t"}
    assert_response :success
    assert_equal "SUPER-SECRET", JSON.parse(@response.body)["payload"]
  end
end
