# frozen_string_literal: true

require "test_helper"

class QrPushEditTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    Settings.enable_logins = true
    Settings.enable_qr_pushes = true
    Rails.application.reload_routes!
    @luca = users(:luca)
    @luca.confirm
    sign_in @luca
  end

  teardown do
    sign_out :user
  end

  test "authenticated user can access edit page for their own qr push" do
    push = Push.create!(
      kind: "qr",
      payload: "QR code content",
      user: @luca
    )

    get edit_push_path(push)
    assert_response :success
    assert_select "textarea#push_payload", text: "QR code content"
  end

  test "edit page shows current expire values for qr push" do
    push = Push.create!(
      kind: "qr",
      payload: "Test QR content",
      user: @luca,
      expire_after_days: 10,
      expire_after_views: 50
    )

    get edit_push_path(push)
    assert_response :success

    # Verify data attributes contain current push values
    assert_select "div[data-knobs-default-days-value='10']"
    assert_select "div[data-knobs-default-views-value='50']"

    # Verify range fields have correct values
    assert_select "input[name='push[expire_after_days]'][value='10']"
    assert_select "input[name='push[expire_after_views]'][value='50']"
  end

  test "can update qr push with valid content" do
    push = Push.create!(
      kind: "qr",
      payload: "Original QR content",
      name: "Original Name",
      user: @luca,
      expire_after_days: 5,
      expire_after_views: 10
    )

    patch push_path(push), params: {
      push: {
        kind: "qr",
        payload: "Updated QR content",
        name: "Updated Name",
        expire_after_days: 7,
        expire_after_views: 15
      }
    }

    assert_redirected_to preview_push_path(push)

    push.reload
    assert_equal "Updated QR content", push.payload
    assert_equal "Updated Name", push.name
    assert_equal 7, push.expire_after_days
    assert_equal 15, push.expire_after_views
  end

  test "update shows validation errors for payload exceeding 1024 characters" do
    push = Push.create!(
      kind: "qr",
      payload: "Valid content",
      user: @luca
    )

    # Create a payload that's too long (over 1024 characters)
    long_payload = "a" * 1025

    patch push_path(push), params: {
      push: {
        kind: "qr",
        payload: long_payload
      }
    }

    assert_response :unprocessable_content
    assert_select "div.alert-danger", text: /QR code payload is too large/
  end

  test "update shows validation errors for empty payload" do
    push = Push.create!(
      kind: "qr",
      payload: "Valid content",
      user: @luca
    )

    patch push_path(push), params: {
      push: {
        kind: "qr",
        payload: ""
      }
    }

    assert_response :unprocessable_content
    assert_select "div.alert-danger", text: /Payload is required/
  end

  test "cannot edit qr push belonging to another user" do
    other_user = users(:one)

    push = Push.create!(
      kind: "qr",
      payload: "Other user's QR content",
      user: other_user
    )

    get edit_push_path(push)
    assert_redirected_to root_path

    patch push_path(push), params: {
      push: {
        kind: "qr",
        payload: "Hacked QR content"
      }
    }
    assert_redirected_to root_path

    push.reload
    assert_equal "Other user's QR content", push.payload
  end

  test "cannot edit expired qr push" do
    push = Push.create!(
      kind: "qr",
      payload: "Expired QR content",
      user: @luca
    )

    # Manually set expired without triggering validations
    push.update_columns(expired: true, expired_on: Time.current, payload_ciphertext: nil)

    get edit_push_path(push)
    assert_redirected_to push_path(push)

    patch push_path(push), params: {
      push: {
        kind: "qr",
        payload: "New QR content"
      }
    }
    assert_redirected_to push_path(push)
  end

  test "edit page shows update button for qr push" do
    push = Push.create!(
      kind: "qr",
      payload: "Test QR content",
      user: @luca
    )

    get edit_push_path(push)
    assert_response :success
    assert_select "button[type=submit]", text: /Update Push/
  end

  test "can update qr push within 1024 character limit" do
    push = Push.create!(
      kind: "qr",
      payload: "Short content",
      user: @luca
    )

    # Create exactly 1024 characters
    valid_payload = "a" * 1024

    patch push_path(push), params: {
      push: {
        kind: "qr",
        payload: valid_payload
      }
    }

    assert_redirected_to preview_push_path(push)
    push.reload
    assert_equal 1024, push.payload.length
  end

  test "update creates audit log for qr push" do
    push = Push.create!(kind: "qr", payload: "https://example.com", user: @luca)

    patch push_path(push), params: {
      push: {payload: "https://updated.com"}
    }

    assert_audit_log_created(push, :edit)
  end

  test "save block is hidden when editing qr push" do
    push = Push.create!(
      kind: "qr",
      payload: "QR code content",
      user: @luca
    )

    get edit_push_path(push)
    assert_response :success

    # Verify save block is not present when editing
    assert_select "div#cookie-save", false, "Save block should not be visible when editing"
  end

  test "save block is visible when creating new qr push" do
    get new_push_path(tab: "qr")
    assert_response :success

    # Verify save block is present when creating
    assert_select "div#cookie-save", true, "Save block should be visible when creating"
  end
end
