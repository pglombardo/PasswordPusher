# frozen_string_literal: true

require "test_helper"

class FilePushJsonCreationTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Settings.enable_logins = true
    Settings.enable_file_pushes = true
    Rails.application.reload_routes!
    @luca = users(:luca)
    @luca.confirm
  end

  def test_basic_json_creation
    post file_pushes_path(format: :json), params: {
                                            file_push: {
                                              payload: "Message",
                                              files: [
                                                fixture_file_upload("monkey.png", "image/jpeg")
                                              ]
                                            }
                                          },
      headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("payload") == false # No payload on create response
    assert res.key?("url_token")
    assert res.key?("name")
    assert_equal "", res["name"]
    assert res.key?("expired")
    assert_equal false, res["expired"]
    assert res.key?("deleted")
    assert_equal false, res["deleted"]
    assert res.key?("deletable_by_viewer")
    assert_equal res.keys.sort, ["expire_after_days", "expire_after_views", "expired", "url_token", "deleted", "deletable_by_viewer", "retrieval_step", "expired_on", "created_at", "updated_at", "days_remaining", "views_remaining", "html_url", "json_url", "name", "note", "passphrase"].sort

    assert_equal res.except("url_token", "created_at", "updated_at", "html_url", "json_url"), {"expire_after_views" => 5,
    "expired" => false,
    "deletable_by_viewer" => true,
    "retrieval_step" => false,
    "expired_on" => nil,
    "passphrase" => "",
    "expire_after_days" => 7,
    "days_remaining" => 7,
    "views_remaining" => 5,
    "deleted" => false,
    "note" => "",
    "name" => ""}

    # These should be default values since we didn't specify them in the params
    assert_equal Settings.files.deletable_pushes_default, res["deletable_by_viewer"]
    assert res.key?("days_remaining")
    assert_equal Settings.files.expire_after_days_default, res["days_remaining"]
    assert res.key?("views_remaining")
    assert_equal Settings.files.expire_after_views_default, res["views_remaining"]
    assert res.key?("expire_after_days")
    assert_equal Settings.files.expire_after_days_default, res["expire_after_days"]
    assert res.key?("expire_after_views")
    assert_equal Settings.files.expire_after_views_default, res["expire_after_views"]
  end

  def test_json_creation_with_uncommon_characters
    post file_pushes_path(format: :json), params: {
                                            file_push: {
                                              payload: "£¬",
                                              files: [
                                                fixture_file_upload("monkey.png", "image/jpeg")
                                              ]
                                            }
                                          },
      headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("payload") == false # No payload on create response
    assert res.key?("url_token")
    assert res.key?("expired")
    assert_equal false, res["expired"]
    assert res.key?("deleted")
    assert_equal false, res["deleted"]
    assert res.key?("deletable_by_viewer")

    # These should be default values since we didn't specify them in the params
    assert_equal Settings.files.deletable_pushes_default, res["deletable_by_viewer"]
    assert res.key?("days_remaining")
    assert_equal Settings.files.expire_after_days_default, res["days_remaining"]
    assert res.key?("views_remaining")
    assert_equal Settings.files.expire_after_views_default, res["views_remaining"]
    assert res.key?("expire_after_days")
    assert_equal Settings.files.expire_after_days_default, res["expire_after_days"]
    assert res.key?("expire_after_views")
    assert_equal Settings.files.expire_after_views_default, res["expire_after_views"]

    # Validate payload
    get "/f/#{res["url_token"]}.json", as: :json
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("payload")
    assert_equal "£¬", res["payload"]
  end

  def test_deletable_by_viewer
    post file_pushes_path(format: :json), params: {
                                            file_push: {
                                              payload: "Message",
                                              deletable_by_viewer: "true",
                                              files: [
                                                fixture_file_upload("monkey.png", "image/jpeg")
                                              ]
                                            }
                                          },
      headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("deletable_by_viewer")
    assert_equal true, res["deletable_by_viewer"]
  end

  def test_not_deletable_by_viewer
    post file_pushes_path(format: :json), params: {
                                            file_push: {
                                              payload: "Message",
                                              deletable_by_viewer: "false",
                                              files: [
                                                fixture_file_upload("monkey.png", "image/jpeg")
                                              ]
                                            }
                                          },
      headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("deletable_by_viewer")
    assert_equal false, res["deletable_by_viewer"]
  end

  def test_deletable_by_viewer_absent_is_default
    post file_pushes_path(format: :json), params: {
                                            file_push: {
                                              payload: "Message",
                                              files: [
                                                fixture_file_upload("monkey.png", "image/jpeg")
                                              ]
                                            }
                                          },
      headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("deletable_by_viewer")
    assert_equal Settings.files.enable_deletable_pushes, res["deletable_by_viewer"]
  end

  def test_custom_days_expiration
    post file_pushes_path(format: :json), params: {
                                            file_push: {
                                              payload: "Message",
                                              expire_after_days: 1,
                                              files: [
                                                fixture_file_upload("monkey.png", "image/jpeg")
                                              ]
                                            }
                                          },
      headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}
    assert_response :success

    res = JSON.parse(@response.body)

    assert res.key?("days_remaining")
    assert_equal 1, res["days_remaining"]

    assert res.key?("expire_after_days")
    assert_equal 1, res["expire_after_days"]
  end

  def test_custom_views_expiration
    post file_pushes_path(format: :json), params: {
                                            file_push: {
                                              payload: "Message",
                                              expire_after_views: 5,
                                              files: [
                                                fixture_file_upload("monkey.png", "image/jpeg")
                                              ]
                                            }
                                          },
      headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}
    assert_response :success

    res = JSON.parse(@response.body)

    assert res.key?("views_remaining")
    assert_equal 5, res["views_remaining"]

    assert res.key?("expire_after_days")
    assert_equal 5, res["expire_after_views"]
  end

  def test_creation_with_kind_on_endpoint_starting_with_p
    post json_pushes_path(format: :json), params: {
                                            password: {
                                              kind: "file",
                                              payload: "Message",
                                              files: [
                                                fixture_file_upload("monkey.png", "image/jpeg")
                                              ]
                                            }
                                          },
      headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}
    assert_response :success

    res = JSON.parse(@response.body)
    url_token = res["url_token"]
    push = Push.find_by(url_token:)
    assert_equal push.kind, "file"
  end

  def test_creation_without_kind_on_endpoint_starting_with_p
    post json_pushes_path(format: :json), params: {
                                            password: {
                                              payload: "Message",
                                              files: [
                                                fixture_file_upload("monkey.png", "image/jpeg")
                                              ]
                                            }
                                          },
      headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}
    assert_response :success

    res = JSON.parse(@response.body)
    url_token = res["url_token"]
    push = Push.find_by(url_token:)
    assert_equal push.kind, "file"
  end

  def test_bad_request
    post file_pushes_path(format: :json), params: {},
      headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}
    assert_response :bad_request
  end
end
