# frozen_string_literal: true

require "application_system_test_case"

class PushViewingWorkflowsTest < ApplicationSystemTestCase
  setup do
    Settings.enable_logins = true
    Settings.enable_password_pushes = true
    Rails.application.reload_routes!

    @push = pushes(:test_push)
    @push.update(
      payload: "MySecretPassword",
      expired: false,
      expire_after_views: 5
    )
    # Clear any existing audit logs to start with 0 views
    @push.audit_logs.destroy_all
  end

  test "viewing a password push" do
    visit push_path(@push)

    # Should show the payload
    assert_text "MySecretPassword", wait: 5
  end

  test "view counter decrements correctly" do
    initial_views_remaining = @push.views_remaining
    initial_view_count = @push.view_count

    visit push_path(@push)

    # Reload push from database
    @push.reload

    # View count should have increased (audit log created)
    assert_equal initial_view_count + 1, @push.view_count

    # Views remaining should have decremented
    assert_equal initial_views_remaining - 1, @push.views_remaining
  end

  test "retrieval step workflow" do
    @push.update(retrieval_step: true, expired: false)

    # When retrieval_step is enabled, the URL points to preliminary page
    # Visit the preliminary page directly (this is what the generated URL would be)
    visit preliminary_push_path(@push)

    # Should be on preliminary page
    assert_current_path preliminary_push_path(@push), wait: 5
    assert_text "Click Here to Proceed", wait: 5

    # Click the link to proceed
    click_link "Click Here to Proceed"

    # Should now be on the actual push page
    assert_current_path push_path(@push), wait: 5
    assert_text "MySecretPassword", wait: 5
  end

  test "expired push shows expiration message" do
    @push.update(expired: true)

    visit push_path(@push)

    # Should show expiration message
    assert_text "expired", wait: 5
  end

  test "push not found shows expired page" do
    visit push_path(id: "nonexistenttoken123")

    # For security, non-existent pushes show expired page (not "not found")
    assert_text "expired", wait: 5
  end

  test "viewing push with remaining views" do
    @push.update(expire_after_views: 3)
    @push.audit_logs.destroy_all

    visit push_path(@push)

    # Should show remaining views (after this view, 2 more views remain)
    assert_text "2 more views", wait: 5
  end

  test "push expires after views are exhausted" do
    @push.update(expire_after_views: 1)
    @push.audit_logs.destroy_all

    # First view
    visit push_path(@push)
    assert_text "MySecretPassword", wait: 5

    # Second view should show expired
    visit push_path(@push)
    @push.reload
    assert @push.expired?, wait: 5
  end

  test "viewing push with passphrase requires passphrase first" do
    @push.update(passphrase: "secret123")

    visit push_path(@push)

    # Should redirect to passphrase page
    assert_current_path passphrase_push_path(@push), wait: 5
    assert_selector "input[name='passphrase']", wait: 5
  end

  test "viewing push shows expiration information" do
    @push.update(expire_after_days: 7, expire_after_views: 5)
    @push.audit_logs.destroy_all

    visit push_path(@push)

    # Should show expiration information (after this view, 4 more views remain)
    assert_text "7", wait: 5
    assert_text "4 more views", wait: 5
  end

  test "viewing push with deletable_by_viewer shows delete button" do
    @push.update(deletable_by_viewer: true, expired: false)

    visit push_path(@push)

    # Should show delete button
    assert_selector "button", text: /delete/i, wait: 5
  end

  test "viewing push without deletable_by_viewer does not show delete button" do
    @push.update(deletable_by_viewer: false, expired: false)

    visit push_path(@push)

    # Should not show delete button for regular users
    assert_no_selector "button", text: /delete/i, wait: 5
  end
end
