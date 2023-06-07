require 'test_helper'

class PasswordJsonAuditTest < ActionDispatch::IntegrationTest
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


  def test_audit_response_for_authenticated
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
    assert res.key?("url_token")
    url_token = res['url_token']

    # Generate views on that push
    3.times do
        get file_push_path(url_token, format: :json)
        assert_response :success
    end

    # Get the Audit Log
    get audit_file_push_path(format: :json), headers: { 'X-User-Email': @luca.email, 'X-User-Token': @luca.authentication_token }, as: :json
    assert_response :success

    res = JSON.parse(@response.body)
    assert res.key?("views")
    assert res['views'].length == 3

    first_view = res['views'].first
    assert first_view.key?('ip')
    assert first_view.key?('user_agent')
    assert first_view.key?('referrer')
    assert first_view.key?('successful')
    assert first_view.key?('created_at')
    assert first_view.key?('updated_at')
    assert first_view.key?('kind')
  end

  def test_no_token_no_audit_log
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
    assert res.key?("url_token")
    url_token = res['url_token']

    # Generate views on that push
    3.times do
        get file_push_path(url_token, format: :json)
        assert_response :success
    end


    # Get the Audit Log without a token
    get audit_file_push_path(format: :json), as: :json
    assert_response :unauthorized

    res = JSON.parse(@response.body)
    assert res.key?("error")
    assert res["error"] == "You need to sign in or sign up before continuing."
  end
end