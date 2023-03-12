require 'test_helper'

class PasswordBlurTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Settings.pw.enable_blur = true
  end

  teardown do
    Settings.pw.enable_blur = true
  end

  def test_blur_enabled
    post passwords_path, params: { password: { payload: 'testpw' } }
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
    Settings.pw.enable_blur = false

    post passwords_path, params: { password: { payload: 'testpw' } }
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