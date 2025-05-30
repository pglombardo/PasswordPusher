# frozen_string_literal: true

require "test_helper"

class FilePushJsonRetrievalTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Settings.enable_logins = true
    Settings.enable_file_pushes = true
    Rails.application.reload_routes!
    @luca = users(:luca)
    @luca.confirm
  end

  def test_view_with_passphrase
    mock_params = {}

    mock_params[:file_push] = {}
    mock_params[:file_push][:payload] = "testpw"
    mock_params[:file_push][:expire_after_views] = 10
    mock_params[:file_push][:files] = [fixture_file_upload("monkey.png", "image/jpeg")]
    mock_params[:file_push][:passphrase] = "asdf"

    mock_headers = {}
    mock_headers["X-User-Email"] = @luca.email
    mock_headers["X-User-Token"] = @luca.authentication_token

    post file_pushes_path(format: :json), params: mock_params, headers: mock_headers
    assert_response :success

    res = JSON.parse(@response.body)
    url_token = res["url_token"]

    # Now try to retrieve the file push without the passphrase
    get "/f/#{url_token}.json"
    assert_response :unauthorized

    res = JSON.parse(@response.body)
    assert res.key?("error")

    # Now try to retrieve the file push WITH the passphrase
    # File push links were generated with '/p/' after unifying controllers and models
    get "/p/#{url_token}.json?passphrase=asdf"
    assert_response :success

    # Now try to retrieve the file push WITH the passphrase
    # File push links were generated with '/f/' before unifying controllers and models
    get "/f/#{url_token}.json?passphrase=asdf"
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("payload")
    assert_equal "testpw", res["payload"]
  end

  def test_view_expiration
    mock_params = {}

    mock_params[:file_push] = {}
    mock_params[:file_push][:payload] = "testpw"
    mock_params[:file_push][:expire_after_views] = 2
    mock_params[:file_push][:files] = [fixture_file_upload("monkey.png", "image/jpeg")]

    mock_headers = {}
    mock_headers["X-User-Email"] = @luca.email
    mock_headers["X-User-Token"] = @luca.authentication_token

    # Create a push with two views
    post file_pushes_path(format: :json), params: mock_params, headers: mock_headers

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
    assert_equal 2, res["expire_after_views"]

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
    assert_equal 2, res["expire_after_views"]

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
    assert_equal 2, res["expire_after_views"]

    # With the third view, we should have an expired push
    get file_push_path(res["url_token"], format: :json)
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("expired")
    assert_equal true, res["expired"]
    assert res.key?("expired_on")
    assert_not_nil res["expired_on"]
    assert res.key?("deleted")
    assert_equal false, res["deleted"]
    assert res.key?("payload")
    assert_nil res["payload"]
    assert res.key?("views_remaining")
    assert_equal 0, res["views_remaining"]
    assert res.key?("expire_after_views")
    assert_equal 2, res["expire_after_views"]
    assert_equal res.except("url_token", "created_at", "updated_at", "expired_on", "json_url", "html_url"), {"expire_after_views" => 2,
    "expired" => true,
    "retrieval_step" => false,
    "passphrase" => nil,
    "expire_after_days" => 7,
    "days_remaining" => 7,
    "views_remaining" => 0,
    "deleted" => false,
    "deletable_by_viewer" => true,
    "payload" => nil,
    "files" => []}
  end
end
