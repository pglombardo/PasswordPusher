# frozen_string_literal: true

require "test_helper"

class FilePushJsonActiveTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Settings.enable_logins = true
    Settings.enable_file_pushes = true
    Rails.application.reload_routes!

    @luca = users(:luca)
    @luca.confirm
  end

  def test_basic_json_expired
    post file_pushes_path(format: :json),
      params: {
        file_push: {
          payload: "Message",
          name: "Test File Push",
          note: "This is a test file push",
          files: [
            fixture_file_upload("monkey.png", "image/jpeg")
          ]
        }
      },
      headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}
    assert_response :success

    get active_file_pushes_path(format: :json), headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}
    assert_response :success

    res = JSON.parse(@response.body)
    push = res.first
    assert_not push.key?("payload")
    assert push.key?("url_token")
    assert push.key?("name")
    assert_equal "Test File Push", push["name"]
    assert push.key?("note")
    assert_equal "This is a test file push", push["note"]
    assert push.key?("expired")
    assert_equal false, push["expired"]
    assert push.key?("expired_on")
    assert push.key?("deleted")
    assert_equal false, push["deleted"]
    assert push.key?("deletable_by_viewer")
    assert_equal true, push["deletable_by_viewer"]
    assert push.key?("files")
    assert_equal 1, push["files"].count
    assert_equal true, push["files"].first.key?("filename")
    assert_equal "monkey.png", push["files"].first["filename"]
    assert_equal true, push["files"].first.key?("content_type")
    assert_equal "image/png", push["files"].first["content_type"]
    assert_equal true, push["files"].first.key?("url")
    assert_match(/\/pfb\/blobs\/redirect\/.*\/monkey.png/, push["files"].first["url"])
    assert_equal push.keys.sort, ["created_at", "days_remaining", "deletable_by_viewer", "deleted", "expire_after_days", "expire_after_views", "expired", "expired_on", "files", "html_url", "json_url", "name", "note", "passphrase", "retrieval_step", "updated_at", "url_token", "views_remaining"].sort
    assert_equal push.except("url_token", "created_at", "updated_at", "html_url", "json_url", "expired_on", "files"), {
      "expire_after_views" => 5,
      "expired" => false,
      "deletable_by_viewer" => true,
      "retrieval_step" => false,
      "passphrase" => "",
      "expire_after_days" => 7,
      "days_remaining" => 7,
      "views_remaining" => 5,
      "deleted" => false,
      "note" => "This is a test file push",
      "name" => "Test File Push"
    }

    # These should be default values since we didn't specify them in the params
    assert_equal Settings.pw.deletable_pushes_default, push["deletable_by_viewer"]
    assert push.key?("days_remaining")
    assert_equal Settings.pw.expire_after_days_default, push["days_remaining"]
    assert push.key?("views_remaining")
    assert_equal Settings.pw.expire_after_views_default, push["views_remaining"]
    assert push.key?("expire_after_days")
    assert_equal Settings.pw.expire_after_days_default, push["expire_after_days"]
    assert push.key?("expire_after_views")
    assert_equal Settings.pw.expire_after_views_default, push["expire_after_views"]
  end
end
