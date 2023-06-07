require 'test_helper'

class FilePushJsonCreationTest < ActionDispatch::IntegrationTest
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

  def test_basic_json_creation
    post file_pushes_path(format: :json), params: {
      file_push: {
        payload: 'Message',
        files: [
          fixture_file_upload('monkey.png', 'image/jpeg')
        ]
      }
    },
    headers: { 'X-User-Email': @luca.email, 'X-User-Token': @luca.authentication_token }
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?('payload') == false # No payload on create response
    assert res.key?('url_token')
    assert res.key?('expired')
    assert_equal false, res['expired']
    assert res.key?('deleted')
    assert_equal false, res['deleted']
    assert res.key?('deletable_by_viewer')
    assert_equal Settings.files.deletable_pushes_default, res['deletable_by_viewer']
    assert res.key?('days_remaining')
    assert_equal Settings.files.expire_after_days_default, res['days_remaining']
    assert res.key?('views_remaining')
    assert_equal Settings.files.expire_after_views_default, res['views_remaining']

    # These should be default values since we didn't specify them in the params
    assert res.key?('expire_after_days')
    assert_equal Settings.files.expire_after_days_default, res['expire_after_days']
    assert res.key?('expire_after_views')
    assert_equal Settings.files.expire_after_views_default, res['expire_after_views']
  end

  def test_json_creation_with_uncommon_characters
    post file_pushes_path(format: :json), params: {
      file_push: {
        payload: '£¬',
        files: [
          fixture_file_upload('monkey.png', 'image/jpeg')
        ]
      }
    },
    headers: { 'X-User-Email': @luca.email, 'X-User-Token': @luca.authentication_token }
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?('payload') == false # No payload on create response
    assert res.key?('url_token')
    assert res.key?('expired')
    assert_equal false, res['expired']
    assert res.key?('deleted')
    assert_equal false, res['deleted']
    assert res.key?('deletable_by_viewer')
    assert_equal Settings.files.deletable_pushes_default, res['deletable_by_viewer']
    assert res.key?('days_remaining')
    assert_equal Settings.files.expire_after_days_default, res['days_remaining']
    assert res.key?('views_remaining')
    assert_equal Settings.files.expire_after_views_default, res['views_remaining']

    # These should be default values since we didn't specify them in the params
    assert res.key?('expire_after_days')
    assert_equal Settings.files.expire_after_days_default, res['expire_after_days']
    assert res.key?('expire_after_views')
    assert_equal Settings.files.expire_after_views_default, res['expire_after_views']

    # Validate payload
    get "/f/#{res["url_token"]}.json", as: :json
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?('payload')
    assert_equal '£¬', res['payload']
  end

  def test_deletable_by_viewer
    post file_pushes_path(format: :json), params: {
      file_push: {
        payload: 'Message',
        deletable_by_viewer: 'true',
        files: [
          fixture_file_upload('monkey.png', 'image/jpeg')
        ]
      }
    },
    headers: { 'X-User-Email': @luca.email, 'X-User-Token': @luca.authentication_token }
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?('deletable_by_viewer')
    assert_equal true, res['deletable_by_viewer']
  end

  def test_not_deletable_by_viewer
    post file_pushes_path(format: :json), params: {
      file_push: {
        payload: 'Message',
        deletable_by_viewer: 'false',
        files: [
          fixture_file_upload('monkey.png', 'image/jpeg')
        ]
      }
    },
    headers: { 'X-User-Email': @luca.email, 'X-User-Token': @luca.authentication_token }
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?('deletable_by_viewer')
    assert_equal false, res['deletable_by_viewer']
  end

  def test_deletable_by_viewer_absent_is_default
    post file_pushes_path(format: :json), params: {
      file_push: {
        payload: 'Message',
        files: [
          fixture_file_upload('monkey.png', 'image/jpeg')
        ]
      }
    },
    headers: { 'X-User-Email': @luca.email, 'X-User-Token': @luca.authentication_token }
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?('deletable_by_viewer')
    assert_equal Settings.files.enable_deletable_pushes, res['deletable_by_viewer']
  end

  def test_custom_days_expiration
    post file_pushes_path(format: :json), params: {
      file_push: {
        payload: 'Message',
        expire_after_days: 1,
        files: [
          fixture_file_upload('monkey.png', 'image/jpeg')
        ]
      }
    },
    headers: { 'X-User-Email': @luca.email, 'X-User-Token': @luca.authentication_token }
    assert_response :success

    res = JSON.parse(@response.body)

    assert res.key?('days_remaining')
    assert_equal 1, res['days_remaining']

    assert res.key?('expire_after_days')
    assert_equal 1, res['expire_after_days']
  end

  def test_custom_views_expiration
    post file_pushes_path(format: :json), params: {
      file_push: {
        payload: 'Message',
        expire_after_views: 5,
        files: [
          fixture_file_upload('monkey.png', 'image/jpeg')
        ]
      }
    },
    headers: { 'X-User-Email': @luca.email, 'X-User-Token': @luca.authentication_token }
    assert_response :success

    res = JSON.parse(@response.body)

    assert res.key?('views_remaining')
    assert_equal 5, res['views_remaining']

    assert res.key?('expire_after_days')
    assert_equal 5, res['expire_after_views']
  end

  def test_bad_request
    post file_pushes_path(format: :json), params: {}, headers: { 'X-User-Email': @luca.email, 'X-User-Token': @luca.authentication_token }
    assert_response :unprocessable_entity

    res = JSON.parse(@response.body)
    assert res.key?('error')
    assert_equal 'No password, text or files provided.', res['error']
    assert_equal 422, @response.status
  end
end
