# frozen_string_literal: true

require "test_helper"

class UrlPushEditTest < ActionDispatch::IntegrationTest
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

  test "authenticated user can access edit page for their own url push" do
    push = Push.create!(
      kind: "url",
      payload: "https://example.com",
      user: @luca
    )

    get edit_push_path(push)
    assert_response :success
    assert_select "input#push_payload[value=?]", "https://example.com"
  end

  test "edit page shows current expire values for url push" do
    push = Push.create!(
      kind: "url",
      payload: "https://example.com",
      user: @luca,
      expire_after_days: 15,
      expire_after_views: 30
    )

    get edit_push_path(push)
    assert_response :success

    # Verify data attributes contain current push values
    assert_select "div[data-knobs-default-days-value='15']"
    assert_select "div[data-knobs-default-views-value='30']"

    # Verify range fields have correct values
    assert_select "input[name='push[expire_after_days]'][value='15']"
    assert_select "input[name='push[expire_after_views]'][value='30']"
  end

  test "can update url push with valid url" do
    push = Push.create!(
      kind: "url",
      payload: "https://example.com",
      name: "Original Name",
      user: @luca,
      expire_after_days: 5,
      expire_after_views: 10
    )

    patch push_path(push), params: {
      push: {
        kind: "url",
        payload: "https://updated-example.com",
        name: "Updated Name",
        expire_after_days: 7,
        expire_after_views: 15
      }
    }

    assert_redirected_to preview_push_path(push)

    push.reload
    assert_equal "https://updated-example.com", push.payload
    assert_equal "Updated Name", push.name
    assert_equal 7, push.expire_after_days
    assert_equal 15, push.expire_after_views
  end

  test "update shows validation errors for invalid url" do
    push = Push.create!(
      kind: "url",
      payload: "https://example.com",
      user: @luca
    )

    patch push_path(push), params: {
      push: {
        kind: "url",
        payload: "not-a-valid-url"
      }
    }

    assert_response :unprocessable_content
    assert_select "div.alert-danger", text: /must be a valid HTTP or HTTPS URL/
  end

  test "cannot edit url push belonging to another user" do
    other_user = users(:one)

    push = Push.create!(
      kind: "url",
      payload: "https://other-user.com",
      user: other_user
    )

    get edit_push_path(push)
    assert_redirected_to root_path

    patch push_path(push), params: {
      push: {
        kind: "url",
        payload: "https://hacked.com"
      }
    }
    assert_redirected_to root_path

    push.reload
    assert_equal "https://other-user.com", push.payload
  end

  test "cannot edit expired url push" do
    push = Push.create!(
      kind: "url",
      payload: "https://example.com",
      user: @luca
    )

    # Manually set expired without triggering validations
    push.update_columns(expired: true, expired_on: Time.current, payload_ciphertext: nil)

    get edit_push_path(push)
    assert_redirected_to push_path(push)

    patch push_path(push), params: {
      push: {
        kind: "url",
        payload: "https://new-url.com"
      }
    }
    assert_redirected_to push_path(push)
  end

  test "edit page shows update button for url push" do
    push = Push.create!(
      kind: "url",
      payload: "https://example.com",
      user: @luca
    )

    get edit_push_path(push)
    assert_response :success
    assert_select "button[type=submit]", text: /Update Push/
  end

  test "update creates audit log for url push" do
    push = Push.create!(kind: "url", payload: "https://example.com", user: @luca)

    patch push_path(push), params: {
      push: {payload: "https://updated.com"}
    }

    assert_audit_log_created(push, :edit)
  end

  test "save block is hidden when editing url push" do
    push = Push.create!(
      kind: "url",
      payload: "https://example.com",
      user: @luca
    )

    get edit_push_path(push)
    assert_response :success

    # Verify save block is not present when editing
    assert_select "div#cookie-save", false, "Save block should not be visible when editing"
  end

  test "save block is visible when creating new url push" do
    get new_push_path(tab: "url")
    assert_response :success

    # Verify save block is present when creating
    assert_select "div#cookie-save", true, "Save block should be visible when creating"
  end
end
