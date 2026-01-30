# frozen_string_literal: true

require "test_helper"

class PasswordEditTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @luca = users(:luca)
    @luca.confirm
    sign_in @luca
  end

  teardown do
    sign_out :user
  end

  test "authenticated user can access edit page for their own push" do
    push = Push.create!(
      kind: "text",
      payload: "Original password",
      user: @luca,
      expire_after_days: 5,
      expire_after_views: 10
    )

    get edit_push_path(push)
    assert_response :success
    assert_select "textarea#push_payload", text: "Original password"
  end

  test "edit page shows correct values for text push" do
    push = Push.create!(
      kind: "text",
      payload: "Test password",
      name: "My Push",
      note: "My note",
      user: @luca,
      expire_after_days: 7,
      expire_after_views: 5,
      retrieval_step: true,
      deletable_by_viewer: true
    )

    get edit_push_path(push)
    assert_response :success

    assert_select "textarea#push_payload", text: "Test password"
    assert_select "input#push_name[value=?]", "My Push"
    assert_select "textarea#push_note", text: "My note"
    assert_select "button[type=submit]", text: /Update Push/
  end

  test "edit page shows current expire values in form" do
    push = Push.create!(
      kind: "text",
      payload: "Test password",
      user: @luca,
      expire_after_days: 12,
      expire_after_views: 25
    )

    get edit_push_path(push)
    assert_response :success

    # Verify data attributes contain current push values
    assert_select "div[data-knobs-default-days-value='12']"
    assert_select "div[data-knobs-default-views-value='25']"

    # Verify range fields have correct values
    assert_select "input[name='push[expire_after_days]'][value='12']"
    assert_select "input[name='push[expire_after_views]'][value='25']"
  end

  test "edit page shows blur and reveal zone when enable_blur is true" do
    Settings.pw.enable_blur = true

    push = Push.create!(
      kind: "text",
      payload: "Secret content",
      user: @luca,
      expire_after_days: 7,
      expire_after_views: 10
    )

    get edit_push_path(push)
    assert_response :success

    # Textarea has spoiler class (blurred by default)
    assert_select "textarea#push_payload.spoiler", 1

    # No autofocus when blurred
    assert_select "textarea#push_payload[autofocus]", 0

    # Reveal zone with instructions is present
    assert_select ".payload-reveal-zone", 1
    assert_match(/Content is hidden for privacy/, response.body)
  ensure
    Settings.pw.enable_blur = true
  end

  test "can update push with valid data" do
    push = Push.create!(
      kind: "text",
      payload: "Original password",
      name: "Original Name",
      user: @luca,
      expire_after_days: 5,
      expire_after_views: 10
    )

    initial_audit_count = push.audit_logs.count

    patch push_path(push), params: {
      push: {
        kind: "text",
        payload: "Updated password",
        name: "Updated Name",
        expire_after_days: 7,
        expire_after_views: 15
      }
    }

    assert_redirected_to preview_push_path(push)
    follow_redirect!
    assert_response :success

    push.reload
    assert_equal "Updated password", push.payload
    assert_equal "Updated Name", push.name
    assert_equal 7, push.expire_after_days
    assert_equal 15, push.expire_after_views

    # Verify audit log entry was created
    assert_equal initial_audit_count + 1, push.audit_logs.count
    assert push.audit_logs.last.edit?
  end

  test "update shows validation errors for invalid data" do
    push = Push.create!(
      kind: "text",
      payload: "Original password",
      user: @luca
    )

    patch push_path(push), params: {
      push: {
        kind: "text",
        payload: ""  # Invalid - empty payload
      }
    }

    assert_response :unprocessable_content
    assert_select "div.alert-danger", text: /Payload is required/
  end

  test "cannot edit push belonging to another user" do
    other_user = users(:one)  # Use existing fixture

    push = Push.create!(
      kind: "text",
      payload: "Other user's password",
      user: other_user
    )

    get edit_push_path(push)
    assert_redirected_to root_path

    patch push_path(push), params: {
      push: {
        kind: "text",
        payload: "Hacked password"
      }
    }
    assert_redirected_to root_path

    push.reload
    assert_equal "Other user's password", push.payload
  end

  test "cannot edit expired push" do
    push = Push.create!(
      kind: "text",
      payload: "Expired password",
      user: @luca
    )

    # Manually set expired without triggering validations
    push.update_columns(expired: true, expired_on: Time.current, payload_ciphertext: nil)

    get edit_push_path(push)
    assert_redirected_to push_path(push)

    patch push_path(push), params: {
      push: {
        kind: "text",
        payload: "New password"
      }
    }
    assert_redirected_to push_path(push)
  end

  test "can update passphrase" do
    push = Push.create!(
      kind: "text",
      payload: "Secret password",
      passphrase: "old_passphrase",
      user: @luca
    )

    patch push_path(push), params: {
      push: {
        kind: "text",
        payload: "Secret password",
        passphrase: "new_passphrase"
      }
    }

    assert_redirected_to preview_push_path(push)
    push.reload
    assert_equal "new_passphrase", push.passphrase
  end

  test "can update note" do
    push = Push.create!(
      kind: "text",
      payload: "Password",
      note: "Original note",
      user: @luca
    )

    patch push_path(push), params: {
      push: {
        kind: "text",
        payload: "Password",
        note: "Updated note"
      }
    }

    assert_redirected_to preview_push_path(push)
    push.reload
    assert_equal "Updated note", push.note
  end

  test "can toggle retrieval_step" do
    push = Push.create!(
      kind: "text",
      payload: "Password",
      retrieval_step: false,
      user: @luca
    )

    patch push_path(push), params: {
      push: {
        kind: "text",
        payload: "Password",
        retrieval_step: "1"
      }
    }

    assert_redirected_to preview_push_path(push)
    push.reload
    assert push.retrieval_step
  end

  test "can toggle deletable_by_viewer" do
    push = Push.create!(
      kind: "text",
      payload: "Password",
      deletable_by_viewer: false,
      user: @luca
    )

    patch push_path(push), params: {
      push: {
        kind: "text",
        payload: "Password",
        deletable_by_viewer: "1"
      }
    }

    assert_redirected_to preview_push_path(push)
    push.reload
    assert push.deletable_by_viewer
  end

  test "cannot change push kind during update" do
    push = Push.create!(
      kind: "text",
      payload: "Original password",
      user: @luca
    )

    original_kind = push.kind

    # Attempt to change kind to URL
    patch push_path(push), params: {
      push: {
        kind: "url",  # This should be ignored
        payload: "https://example.com"
      }
    }

    push.reload
    assert_equal original_kind, push.kind, "Push kind should not change"
    # Should still be text kind, so URL validation shouldn't apply
    assert_equal "https://example.com", push.payload
  end

  test "unauthenticated user cannot access edit page" do
    sign_out @luca

    push = Push.create!(
      kind: "text",
      payload: "Secret password",
      user: @luca
    )

    get edit_push_path(push)
    assert_redirected_to new_user_session_path
  end

  test "unauthenticated user cannot update push" do
    sign_out @luca

    push = Push.create!(
      kind: "text",
      payload: "Original password",
      user: @luca
    )

    patch push_path(push), params: {
      push: {payload: "Hacked password"}
    }

    assert_redirected_to new_user_session_path
    push.reload
    assert_equal "Original password", push.payload
  end

  test "cannot edit anonymous push even if logged in" do
    anonymous_push = Push.create!(
      kind: "text",
      payload: "Anonymous password",
      user: nil  # No owner
    )

    get edit_push_path(anonymous_push)
    # Should fail ownership check since push.user_id (nil) != current_user.id
    assert_redirected_to root_path
  end

  test "cannot reduce views below already consumed" do
    push = Push.create!(
      kind: "text",
      payload: "Password",
      expire_after_views: 10,
      user: @luca
    )

    # Simulate 8 views
    8.times { AuditLog.create!(push: push, kind: :view, ip: "1.2.3.4") }

    # User tries to reduce to 5 views (less than already consumed)
    patch push_path(push), params: {
      push: {expire_after_views: 5}
    }

    # Server-side validation should reject this
    assert_response :unprocessable_content
    assert_select "div.alert-danger", text: /must be at least 9/

    push.reload
    assert_equal 10, push.expire_after_views  # Should remain unchanged
  end

  test "can set views to exactly consumed + 1" do
    push = Push.create!(
      kind: "text",
      payload: "Password",
      expire_after_views: 10,
      user: @luca
    )

    # Simulate 5 views
    5.times { AuditLog.create!(push: push, kind: :view, ip: "1.2.3.4") }

    # User sets to exactly consumed + 1 (minimum allowed)
    patch push_path(push), params: {
      push: {expire_after_views: 6}
    }

    assert_redirected_to preview_push_path(push)
    push.reload
    assert_equal 6, push.expire_after_views
    assert_equal 1, push.views_remaining
  end

  test "cannot reduce days below already elapsed" do
    push = Push.create!(
      kind: "text",
      payload: "Password",
      expire_after_days: 10,
      user: @luca
    )

    # Simulate 5 days passing
    push.update_column(:created_at, 5.days.ago)

    # User tries to reduce to 3 days (less than already elapsed)
    patch push_path(push), params: {
      push: {expire_after_days: 3}
    }

    # Server-side validation should reject this
    assert_response :unprocessable_content
    assert_select "div.alert-danger", text: /must be at least 6/

    push.reload
    assert_equal 10, push.expire_after_days  # Should remain unchanged
  end

  test "can set days to exactly elapsed + 1" do
    push = Push.create!(
      kind: "text",
      payload: "Password",
      expire_after_days: 10,
      user: @luca
    )

    # Simulate 5 days passing
    push.update_column(:created_at, 5.days.ago)

    # User sets to exactly elapsed + 1 (minimum allowed)
    patch push_path(push), params: {
      push: {expire_after_days: 6}
    }

    assert_redirected_to preview_push_path(push)
    push.reload
    assert_equal 6, push.expire_after_days
    assert_equal 1, push.days_remaining
  end

  test "can remove passphrase by setting empty string" do
    push = Push.create!(
      kind: "text",
      payload: "Secret password",
      passphrase: "old_passphrase",
      user: @luca
    )

    patch push_path(push), params: {
      push: {
        payload: "Secret password",
        passphrase: ""  # Remove passphrase
      }
    }

    push.reload
    assert push.passphrase.blank?, "Expected passphrase to be blank but got: #{push.passphrase.inspect}"
  end

  test "unchanged expiration values are filtered out" do
    push = Push.create!(
      kind: "text",
      payload: "Password",
      expire_after_days: 7,
      expire_after_views: 10,
      user: @luca
    )

    # Simulate 3 days passing
    push.update_column(:created_at, 3.days.ago)

    # Submit with current remaining values (should be filtered)
    patch push_path(push), params: {
      push: {
        payload: "Updated password",
        expire_after_days: 4,  # Current remaining = 7-3 = 4
        expire_after_views: 10  # Current remaining = 10
      }
    }

    push.reload
    assert_equal 7, push.expire_after_days  # Should remain unchanged
    assert_equal 10, push.expire_after_views
  end

  test "save block is hidden when editing password push" do
    push = Push.create!(
      kind: "text",
      payload: "Password",
      user: @luca
    )

    get edit_push_path(push)
    assert_response :success

    # Verify save block is not present when editing
    assert_select "div#cookie-save", false, "Save block should not be visible when editing"
  end

  test "save block is visible when creating new password push" do
    get new_push_path(tab: "text")
    assert_response :success

    # Verify save block is present when creating
    assert_select "div#cookie-save", true, "Save block should be visible when creating"
  end
end
