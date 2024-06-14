# frozen_string_literal: true

require "test_helper"

class PasswordCreationTest < ActionDispatch::IntegrationTest
  def test_password_not_found
    # Non existant push should return the expired page
    get "/p/doesnotexist"
    assert_response :success

    # Validate the expiration page
    p_tags = assert_select "p"
    assert p_tags[0].text.include?("We apologize but this secret link has expired.")
  end

  def test_password_preliminary_not_found
    # Non existant push should return the expired page
    get "/p/doesnotexist/r"
    assert_response :success

    # Validate the expiration page
    p_tags = assert_select "p"
    assert p_tags[0].text.include?("We apologize but this secret link has expired.")
  end
end
