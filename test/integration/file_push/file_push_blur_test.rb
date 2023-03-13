require 'test_helper'

class FilePushBlurTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Settings.enable_logins = true
    Settings.enable_file_pushes = true
    Rails.application.reload_routes!
    @luca = users(:luca)
    @luca.confirm
    sign_in @luca

    Settings.files.enable_blur = true
  end

  teardown do
    sign_out :user
    Settings.files.enable_blur = true
  end

  def test_blur_enabled
    post file_pushes_path, params: { 
      file_push: { 
        payload: 'Message',
        files: [ 
          fixture_file_upload('monkey.png', 'image/jpeg')
        ]
      }
    }
    assert_response :redirect

    # Preview page
    follow_redirect!
    assert_response :success
    assert_select 'h2', 'Your push has been created.'

    # File Push page
    get request.url.sub('/preview', '')
    assert_response :success

    # Validate that blur is enabled
    tags = assert_select '#push_payload'
    assert tags.first.attr("class").include?("spoiler")
  end
  
  def test_blur_when_disabled
    Settings.files.enable_blur = false

    post file_pushes_path, params: { 
      file_push: { 
        payload: 'Message',
        files: [ 
          fixture_file_upload('monkey.png', 'image/jpeg')
        ]
      }
    }
    assert_response :redirect

    # Preview page
    follow_redirect!
    assert_response :success
    assert_select 'h2', 'Your push has been created.'

    # File Push page
    get request.url.sub('/preview', '')
    assert_response :success

    # Validate that blur is enabled
    tags = assert_select '#push_payload'
    assert !tags.first.attr("class").include?("spoiler")
  end
end