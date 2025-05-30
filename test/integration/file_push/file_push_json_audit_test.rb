# frozen_string_literal: true

require "test_helper"

class FilePushJsonAuditTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Settings.enable_logins = true
    Settings.enable_file_pushes = true
    Rails.application.reload_routes!
    @luca = users(:luca)
    @luca.confirm
  end

  def test_audit_response_for_authenticated
    post file_pushes_path(format: :json), params: {
                                            file_push: {
                                              payload: "testpw",
                                              expire_after_views: 2,
                                              files: [
                                                fixture_file_upload("monkey.png", "image/jpeg")
                                              ]
                                            }
                                          },
      headers: {"X-User-Email": @luca.email,
                "X-User-Token": @luca.authentication_token}
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("url_token")
    url_token = res["url_token"]

    # Generate views on that push
    3.times do
      get file_push_path(url_token, format: :json)
      assert_response :success
    end

    # Get the Audit Log
    get audit_file_push_path(format: :json),
      headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}, as: :json
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("views")
    assert res["views"].length == 4

    first_view = res["views"].first
    assert first_view.key?("ip")
    assert first_view.key?("user_agent")
    assert first_view.key?("referrer")
    assert first_view.key?("created_at")
    assert first_view.key?("updated_at")
    assert first_view.key?("kind")
    assert_equal res["views"].map { |view| view.except("created_at", "updated_at") }, [{"ip" => "127.0.0.1", "user_agent" => "", "referrer" => "", "kind" => "creation"}, {"ip" => "127.0.0.1", "user_agent" => "", "referrer" => "", "kind" => "view"}, {"ip" => "127.0.0.1", "user_agent" => "", "referrer" => "", "kind" => "view"}, {"ip" => "127.0.0.1", "user_agent" => "", "referrer" => "", "kind" => "failed_view"}]
  end

  def test_audit_response_for_created_expired_successful_and_unsuccessful_views
    post file_pushes_path(format: :json), params: {
                                            file_push: {
                                              payload: "testpw",
                                              passphrase: "asdf",
                                              expire_after_views: 3,
                                              files: [
                                                fixture_file_upload("monkey.png", "image/jpeg")
                                              ]
                                            }
                                          },
      headers: {"X-User-Email": @luca.email,
                "X-User-Token": @luca.authentication_token}
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("url_token")
    url_token = res["url_token"]

    # Generate views on that push
    2.times do
      get file_push_path(url_token, format: :json, passphrase: "asdf")
      assert_response :success
    end

    # Generate unsuccessful views on that push because of wrong passphrase
    get file_push_path(url_token, format: :json)
    assert_response :unauthorized

    delete file_push_path(url_token, format: :json),
      headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}, as: :json
    assert_response :success

    # Generate unsuccessful views on that push
    2.times do
      get file_push_path(url_token, format: :json)
      assert_response :success
    end

    # Get the Audit Log
    get audit_file_push_path(format: :json),
      headers: {"X-User-Email": @luca.email, "X-User-Token": @luca.authentication_token}, as: :json
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("views")
    assert_equal 7, res["views"].length

    first_view = res["views"].first
    assert first_view.key?("ip")
    assert first_view.key?("user_agent")
    assert first_view.key?("referrer")
    assert first_view.key?("created_at")
    assert first_view.key?("updated_at")
    assert first_view.key?("kind")
    assert_equal res["views"].map { |view| view.except("created_at", "updated_at") }, [{"ip" => "127.0.0.1", "user_agent" => "", "referrer" => "", "kind" => "creation"}, {"ip" => "127.0.0.1", "user_agent" => "", "referrer" => "", "kind" => "view"}, {"ip" => "127.0.0.1", "user_agent" => "", "referrer" => "", "kind" => "view"}, {"ip" => "127.0.0.1", "user_agent" => "", "referrer" => "", "kind" => "failed_passphrase"}, {"ip" => "127.0.0.1", "user_agent" => "", "referrer" => "", "kind" => "expire"}, {"ip" => "127.0.0.1", "user_agent" => "", "referrer" => "", "kind" => "failed_view"}, {"ip" => "127.0.0.1", "user_agent" => "", "referrer" => "", "kind" => "failed_view"}]
  end

  def test_no_token_no_audit_log
    post file_pushes_path(format: :json), params: {
                                            file_push: {
                                              payload: "testpw",
                                              expire_after_views: 2,
                                              files: [
                                                fixture_file_upload("monkey.png", "image/jpeg")
                                              ]
                                            }
                                          },
      headers: {"X-User-Email": @luca.email,
                "X-User-Token": @luca.authentication_token}
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("url_token")
    url_token = res["url_token"]

    # Generate views on that push
    3.times do
      get file_push_path(url_token, format: :json)
      assert_response :success
    end

    # Get the Audit Log without a token
    get audit_file_push_path(format: :json), as: :json
    assert_response :unauthorized
  end
end
