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
    first_res = res.first
    assert_not first_res.key?("payload")
    assert first_res.key?("url_token")
    assert first_res.key?("name")
    assert_equal "Test File Push", first_res["name"]
    assert first_res.key?("note")
    assert_equal "This is a test file push", first_res["note"]
    assert first_res.key?("expired")
    assert_equal false, first_res["expired"]
    assert first_res.key?("expired_on")
    assert first_res.key?("deleted")
    assert_equal false, first_res["deleted"]
    assert first_res.key?("deletable_by_viewer")
    assert_equal true, first_res["deletable_by_viewer"]
    assert first_res.key?("files")
    assert_equal 1, first_res["files"].count
    # p first_res["files"]
    # => [{"filename" => "monkey.png", "content_type" => "image/png", "url" => "http://www.example.com/pfb/blobs/redirect/eyJfcmFpbHMiOnsiZGF0YSI6MSwiZXhwIjoiMjAyNS0wNy0wMlQyMToyODoyNi43MzhaIiwicHVyIjoiYmxvYl9pZCJ9fQ==--98a8c59aa58c4c6a943c4eb27cec92c2c04434fd/monkey.png"}]
    assert_equal true, first_res["files"].first.key?("filename")
    assert_equal "monkey.png", first_res["files"].first["filename"]
    assert_equal true, first_res["files"].first.key?("content_type")
    assert_equal "image/png", first_res["files"].first["content_type"]
    assert_equal true, first_res["files"].first.key?("url")
    assert_match(/\/pfb\/blobs\/redirect\/.*\/monkey.png/, first_res["files"].first["url"])
    assert_equal first_res.keys.sort, ["created_at", "days_remaining", "deletable_by_viewer", "deleted", "expire_after_days", "expire_after_views", "expired", "expired_on", "files", "html_url", "json_url", "name", "note", "passphrase", "retrieval_step", "updated_at", "url_token", "views_remaining"].sort
    assert_equal first_res.except("url_token", "created_at", "updated_at", "html_url", "json_url", "expired_on", "files"), {"expire_after_views" => 5,
      "expired" => false,
      "deletable_by_viewer" => true,
      "retrieval_step" => false,
      "passphrase" => "",
      "expire_after_days" => 7,
      "days_remaining" => 7,
      "views_remaining" => 5,
      "deleted" => false,
      "note" => "This is a test file push",
      "name" => "Test File Push"}

    # These should be default values since we didn't specify them in the params
    assert_equal Settings.pw.deletable_pushes_default, first_res["deletable_by_viewer"]
    assert first_res.key?("days_remaining")
    assert_equal Settings.pw.expire_after_days_default, first_res["days_remaining"]
    assert first_res.key?("views_remaining")
    assert_equal Settings.pw.expire_after_views_default, first_res["views_remaining"]
    assert first_res.key?("expire_after_days")
    assert_equal Settings.pw.expire_after_days_default, first_res["expire_after_days"]
    assert first_res.key?("expire_after_views")
    assert_equal Settings.pw.expire_after_views_default, first_res["expire_after_views"]
  end
end
