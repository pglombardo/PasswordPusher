# frozen_string_literal: true

require "test_helper"

class QrIndexTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Settings.enable_logins = true
    Settings.enable_qr_pushes = true

    @luca = users(:luca)
    @luca.confirm
    sign_in @luca
  end

  teardown do
    sign_out :user
  end

  def test_active
    get new_push_path(tab: "qr")
    assert_response :success

    post pushes_path, params: {
      push: {
        kind: "qr",
        payload: "testqr",
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
    assert_select "th", 6 # 6 columns in the table

    # Verify that the table headers exist with the expected content
    assert_select "th", /Name or ID/ # First column should contain 'Name' or 'ID'
    assert_select "th", /Kind/ # Second column
    assert_select "th", /Created/ # Third column
    assert_select "th", /Note/ # Fourth column
    assert_select "th", /Remaining/ # Fifth column

    # Verify that our created file push appears in the list
    assert_select "td", "Test Password"

    # Verify the push controls buttons
    # Since this is an active push, both Preview and Audit buttons should be present
    assert_select "div[aria-label='Push Controls']", 1 do |controls|
      assert_select controls.first, "a", 2 # Should have 2 buttons (Preview and Audit)

      # Check the text content of the buttons
      assert_select controls.first, "a", text: "Preview", count: 1
      assert_select controls.first, "a", text: "Audit", count: 1
    end

    # Expire the push
    delete expire_push_path(@luca.pushes.last)
    assert_response :redirect
    follow_redirect!

    # Verify the push is now expired
    assert @luca.pushes.last.expired

    # Check the expired pushes list
    get pushes_path(filter: "expired")
    assert_response :success

    # Verify the push controls buttons
    # Since this is an expired push, only Audit button should be present
    assert_select "div[aria-label='Push Controls']", 1 do |controls|
      assert_select controls.first, "a", 1 # Should have 1 buttons (Audit)

      # Check the text content of the buttons
      assert_select controls.first, "a", text: "Audit", count: 1
    end
  end
end
