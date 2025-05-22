# frozen_string_literal: true

require "test_helper"

class PasswordActiveTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Settings.enable_logins = true
    Rails.application.reload_routes!
    @luca = users(:luca)
    @luca.confirm
    sign_in @luca
  end

  teardown do
    sign_out :user
  end

  def test_active
    get new_push_path(tab: "text")
    assert_response :success

    post pushes_path, params: {
      push: {
        kind: "text",
        payload: "testpw",
        name: "Test Password"
      }
    }
    assert_response :redirect

    follow_redirect!
    assert_response :success
    assert_select "h2", "Your push has been created."

    get pushes_path(filter: "active")
    assert_response :success

    # Just verify that we have the expected number of th elements
    assert_select "th", 5 # 5 columns in the table

    # Verify that the table headers exist with the expected content
    assert_select "th", /Name or ID/ # First column should contain 'Name' or 'ID'
    assert_select "th", /Created/ # Second column
    assert_select "th", /Note/ # Third column
    assert_select "th", /Views-Days/ # Fourth column

    # Verify that our created file push appears in the list
    assert_select "td", "Test Password"
  end
end
