# frozen_string_literal: true

require "test_helper"

class UrlDeletionTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Settings.enable_logins = true
    Settings.enable_url_pushes = true
    Rails.application.reload_routes!
    @luca = users(:luca)
    @luca.confirm
    sign_in @luca
  end

  teardown do
    sign_out :user
  end

  def test_deletion_by_owner
    get new_push_path(tab: "url")
    assert_response :success

    post pushes_path, params: {
      push: {
        kind: "url",
        payload: "https://the0x00.dev"
      }
    }
    assert_response :redirect

    # preview
    follow_redirect!
    assert_response :success
    assert_select "h2", "Your push has been created."

    # Delete the file_push
    delete request.url.sub("/preview", "/expire")
    assert_response :redirect

    # Get redirected to the password that is now expired
    follow_redirect!
    assert_response :success
  end

  def test_end_user_failed_deletion
    get new_push_path(tab: "url")
    assert_response :success

    post pushes_path, params: {
      push: {
        kind: "url",
        payload: "https://the0x00.dev"
      }
    }
    assert_response :redirect

    # preview
    follow_redirect!
    assert_response :success
    assert_select "h2", "Your push has been created."

    # Sign out user to test anonymous end user deletion
    sign_out :user

    # Delete the file_push
    delete request.url.sub("/preview", "/expire")
    assert_response :redirect

    # Get redirected after failed trying
    follow_redirect!
    assert_response :success

    # Check that we're redirected to root path
    assert_equal path, root_path
  end
end
