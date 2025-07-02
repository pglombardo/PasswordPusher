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
    assert_equal 1, JSON.parse(first_res["files"]).count
    # p JSON.parse(first_res["files"])
    # => {"monkey.png" => "/pfb/blobs/redirect/eyJfcmFpbHMiOnsiZGF0YSI6MSwiZXhwIjoiMjAyNS0wNy0wMlQyMToyMDoxNS4xNzBaIiwicHVyIjoiYmxvYl9pZCJ9fQ==--6e3f646b9f57ea24e0753fd3e1af4240c6442ec3/monkey.png"}
    assert_equal true, JSON.parse(first_res["files"]).key?("monkey.png")
    assert_match(/\/pfb\/blobs\/redirect\/.*\/monkey.png/, JSON.parse(first_res["files"])["monkey.png"])
    assert_equal first_res.keys.sort, ["created_at", "days_remaining", "deletable_by_viewer", "deleted", "expire_after_days", "expire_after_views", "expired", "expired_on", "files", "name", "note", "retrieval_step", "updated_at", "url_token", "views_remaining"].sort
    assert_equal first_res.except("url_token", "created_at", "updated_at", "expired_on", "files"), {
      "expire_after_days" => 7,
      "expire_after_views" => 5,
      "expired" => false,
      "deleted" => false,
      "deletable_by_viewer" => true,
      "retrieval_step" => false,
      "name" => "Test File Push",
      "note" => "This is a test file push",
      "days_remaining" => 7,
      "views_remaining" => 5
    }

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
