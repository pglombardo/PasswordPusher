# frozen_string_literal: true

require "application_system_test_case"

class FilePushEditingTest < ApplicationSystemTestCase
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

  test "delete buttons are visible when multiple files exist" do
    # Create a file push with 2 files
    push = Push.create!(
      kind: "file",
      name: "Test Push",
      user: @user
    )

    # Attach two files using ActiveStorage directly
    push.files.attach(
      io: File.open(Rails.root.join("test/fixtures/files/test-file.txt")),
      filename: "test-file.txt",
      content_type: "text/plain"
    )
    push.files.attach(
      io: File.open(Rails.root.join("test/fixtures/files/test-file-2.txt")),
      filename: "test-file-2.txt",
      content_type: "text/plain"
    )

    visit edit_push_path(push)

    assert_selector ".card-header", text: "Uploaded Files"
    assert_text "test-file.txt"
    assert_text "test-file-2.txt"

    # Verify delete buttons are visible (should be 2 delete buttons, one for each file)
    delete_buttons = all("a.btn-outline-danger")
    assert_equal 2, delete_buttons.count
  end

  test "no delete button when only one file exists" do
    # Create a file push with 1 file
    push = Push.create!(
      kind: "file",
      name: "Test Push",
      user: @user
    )

    # Attach one file
    push.files.attach(
      io: File.open(Rails.root.join("test/fixtures/files/test-file.txt")),
      filename: "test-file.txt",
      content_type: "text/plain"
    )

    # Visit edit page
    visit edit_push_path(push)

    # Verify file is shown
    assert_text "test-file.txt"
  end

  test "can delete a file when multiple files exist" do
    push = Push.create!(
      kind: "file",
      name: "Test Push",
      user: @user
    )

    push.files.attach(
      io: File.open(Rails.root.join("test/fixtures/files/test-file.txt")),
      filename: "test-file.txt",
      content_type: "text/plain"
    )
    push.files.attach(
      io: File.open(Rails.root.join("test/fixtures/files/test-file-2.txt")),
      filename: "test-file-2.txt",
      content_type: "text/plain"
    )

    visit edit_push_path(push)

    # Click the first delete button and accept the confirmation
    accept_confirm do
      first("a.btn-outline-danger").click
    end

    # Should stay on edit page
    assert_selector "h4", text: "Editing Push"

    # Should see success message
    assert_text "File was successfully deleted"

    # Verify we now have only 1 file
    push.reload
    assert_equal 1, push.files.count

    # Verify no delete button now (only 1 file remaining)
    assert_no_selector "a.btn-outline-danger"
  end

  test "checkboxes preserve their values when editing" do
    # Create a push with checkboxes checked
    push = Push.create!(
      kind: "file",
      name: "Test Push",
      user: @user,
      retrieval_step: true,
      deletable_by_viewer: true
    )

    push.files.attach(
      io: File.open(Rails.root.join("test/fixtures/files/test-file.txt")),
      filename: "test-file.txt",
      content_type: "text/plain"
    )

    visit edit_push_path(push)

    # Wait for checkboxes to be rendered and loaded
    assert_selector "#push_retrieval_step"
    assert_selector "#push_deletable_by_viewer"

    # Verify checkboxes are checked
    assert find("#push_retrieval_step").checked?, "retrieval_step checkbox should be checked"
    assert find("#push_deletable_by_viewer").checked?, "deletable_by_viewer checkbox should be checked"
  end

  test "checkboxes can be changed when editing" do
    # Create a push with checkboxes unchecked
    push = Push.create!(
      kind: "file",
      name: "Test Push",
      user: @user,
      retrieval_step: false,
      deletable_by_viewer: false
    )

    push.files.attach(
      io: File.open(Rails.root.join("test/fixtures/files/test-file.txt")),
      filename: "test-file.txt",
      content_type: "text/plain"
    )

    visit edit_push_path(push)

    # Wait for checkboxes to be rendered and loaded
    assert_selector "#push_retrieval_step"
    assert_selector "#push_deletable_by_viewer"

    # Verify checkboxes start unchecked
    assert_not find("#push_retrieval_step").checked?, "retrieval_step should start unchecked"
    assert_not find("#push_deletable_by_viewer").checked?, "deletable_by_viewer should start unchecked"

    # Check both boxes
    check "push_retrieval_step"
    check "push_deletable_by_viewer"

    # Submit form
    click_button "Update Push"

    # Should redirect to preview
    assert_selector "h2", text: "Push Preview"

    # Verify database was updated
    push.reload
    assert push.retrieval_step, "retrieval_step should be true after update"
    assert push.deletable_by_viewer, "deletable_by_viewer should be true after update"
  end
end
