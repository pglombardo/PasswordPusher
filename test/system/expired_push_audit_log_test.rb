# frozen_string_literal: true

require "application_system_test_case"

class ExpiredPushAuditLogTest < ApplicationSystemTestCase
  setup do
    Settings.enable_logins = true
    Settings.enable_file_pushes = true
    Rails.application.reload_routes!

    @user = users(:luca)
    @user.confirm
    login_as(@user, scope: :user)
  end

  teardown do
    logout(:user)
  end

  test "failed update attempt on expired push shows in audit log" do
    # Create an expired text push
    push = Push.create!(
      kind: "text",
      payload: "secret password",
      user: @user,
      expired: true
    )

    # Clear any existing audit logs
    push.audit_logs.destroy_all

    # Visit the edit page
    visit edit_push_path(push)

    # Try to update a restricted field (passphrase) by manipulating the form
    # Use execute_script to enable the passphrase field that's disabled for expired pushes
    execute_script("document.querySelector('input[name=\"push[passphrase]\"]').removeAttribute('disabled')")

    fill_in "push_passphrase", with: "NewPassphrase123"
    click_button "Update"

    # Should see the error message
    assert_text "Expired pushes can only have their note or name updated"

    # Now visit the audit log page
    visit audit_push_path(push)

    # Should see the failed update audit log entry
    assert_selector ".list-group-item-danger", text: "Failed update attempt"
    assert_text "Failed update attempt"

    # Verify the audit log was created
    push.reload
    assert_equal 1, push.audit_logs.count
    assert_equal "failed_update", push.audit_logs.last.kind
  end

  test "failed file upload attempt on expired file push shows in audit log" do
    # Create an expired file push
    push = Push.create!(
      kind: "file",
      user: @user,
      expired: true
    )

    # Attach a file
    push.files.attach(
      io: File.open(Rails.root.join("test/fixtures/files/test-file.txt")),
      filename: "test-file.txt",
      content_type: "text/plain"
    )

    # Clear any existing audit logs
    push.audit_logs.destroy_all

    # Visit the edit page
    visit edit_push_path(push)

    # Try to upload a new file by enabling the file input
    execute_script("document.querySelector('input[type=\"file\"]').removeAttribute('disabled')")

    attach_file "push_files", Rails.root.join("test/fixtures/files/test-file-2.txt")
    click_button "Update"

    # Should see the error message
    assert_text "Files cannot be uploaded to expired pushes"

    # Now visit the audit log page
    visit audit_push_path(push)

    # Should see the failed update audit log entry
    assert_selector ".list-group-item-danger", text: "Failed update attempt"
    assert_text "Failed update attempt"

    # Verify the audit log was created
    push.reload
    assert_equal 1, push.audit_logs.count
    assert_equal "failed_update", push.audit_logs.last.kind
  end

  test "successful note update on expired push does not create failed_update log" do
    # Create an expired text push
    push = Push.create!(
      kind: "text",
      payload: "secret password",
      user: @user,
      expired: true,
      note: "Original note"
    )

    # Clear any existing audit logs
    push.audit_logs.destroy_all

    # Visit the edit page
    visit edit_push_path(push)

    # Update only the note (which is allowed)
    fill_in "push_note", with: "Updated note for records"
    click_button "Update"

    # Should see success message
    assert_text "Note was successfully updated"

    # Visit the audit log page
    visit audit_push_path(push)

    # Should see the update_push log, not failed_update
    assert_selector ".list-group-item-warning", text: "Updated on"
    assert_no_selector ".list-group-item-danger", text: "Failed update attempt"

    # Verify the correct audit log was created
    push.reload
    assert_equal 1, push.audit_logs.count
    assert_equal "update_push", push.audit_logs.last.kind
  end
end
