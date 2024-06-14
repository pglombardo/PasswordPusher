# frozen_string_literal: true

require "test_helper"

class PasswordCreationTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Settings.enable_logins = true
    Settings.enable_file_pushes = true
    Rails.application.reload_routes!
  end

  def test_password_not_found
    # Non existant push should return the expired page
    get file_push_path("doesnotexist")
    assert_response :success

    # Validate the expiration page
    p_tags = assert_select "p"
    assert p_tags[0].text.include?("We apologize but this secret link has expired.")
  end

  def test_password_preliminary_not_found
    # Non existant push should return the expired page
    get preliminary_file_push_path("doesnotexist")
    assert_response :success

    # Validate the expiration page
    p_tags = assert_select "p"
    assert p_tags[0].text.include?("We apologize but this secret link has expired.")
  end
end
