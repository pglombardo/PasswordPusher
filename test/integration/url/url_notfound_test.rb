# frozen_string_literal: true

require "test_helper"

class UrlNotFoundTest < ActionDispatch::IntegrationTest
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
    sign_out @luca
  end

  def test_url_not_found
    # Non existant push should return the expired page
    get "/p/doesnotexist"
    assert_response :success

    # Validate the expiration page
    p_tags = assert_select "p"
    assert p_tags[0].text.include?("We apologize but this secret link has expired.")
  end

  def test_url_preliminary_not_found
    # Non existant push should return the expired page
    get "/p/doesnotexist/r"
    assert_response :success

    # Validate the expiration page
    p_tags = assert_select "p"
    assert p_tags[0].text.include?("We apologize but this secret link has expired.")
  end
end
