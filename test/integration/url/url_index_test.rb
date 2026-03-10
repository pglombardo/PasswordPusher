# frozen_string_literal: true

require "test_helper"

class UrlIndexTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Settings.enable_url_pushes = true
    Rails.application.reload_routes!
    @luca = users(:luca)
    sign_in @luca
  end

  teardown do
    sign_out :user
  end

  def test_index
    get new_push_path(tab: "url")
    assert_response :success

    post pushes_path, params: {
      push: {
        kind: "url",
        payload: "https://the0x00.dev",
        name: "Test URL"
      }
    }
    assert_response :redirect

    follow_redirect!
    assert_response :success
    assert_select "h2", "Push Created"

    get pushes_path(filter: "active")
    assert_response :success

    # Just verify that we have the expected number of th elements
    assert_select "th", 6 # 6 columns in the table

    # Verify that the table headers exist with the expected content
    assert_select "th", /Name \/ ID/
    assert_select "th", /Type/
    assert_select "th", /Created/
    assert_select "th", /Note/
    assert_select "th", /Status/

    # Verify that our created URL push appears in the list
    assert_select "td", "Test URL"

    # Verify the push controls buttons
    # Since this is an active push, Preview, Edit, and Audit buttons should be present
    assert_select "div[aria-label='Push Controls']", 1 do |controls|
      assert_select controls.first, "a", 3
      assert_select controls.first, "a[title='Preview']", count: 1
      assert_select controls.first, "a[title='Edit']", count: 1
      assert_select controls.first, "a[title='Audit Log']", count: 1
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
      assert_select controls.first, "a", 1
      assert_select controls.first, "a[title='Audit Log']", count: 1
    end
  end
end
