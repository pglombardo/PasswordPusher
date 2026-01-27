# frozen_string_literal: true

require "test_helper"

class FilePushEditTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include ActionDispatch::TestProcess

  setup do
    Settings.enable_logins = true
    Settings.enable_file_pushes = true
    Rails.application.reload_routes!
    @luca = users(:luca)
    @luca.confirm
    sign_in @luca
  end

  teardown do
    sign_out :user
  end

  test "authenticated user can access edit page for their own file push" do
    push = Push.create!(
      kind: "file",
      payload: "Message for files",
      user: @luca
    )
    push.files.attach(fixture_file_upload("monkey.png", "image/png"))

    get edit_push_path(push)
    assert_response :success
    assert_select "textarea#push_payload", text: "Message for files"
  end

  test "edit page shows current expire values for file push" do
    push = Push.create!(
      kind: "file",
      payload: "Test message",
      user: @luca,
      expire_after_days: 8,
      expire_after_views: 20
    )
    push.files.attach(fixture_file_upload("monkey.png", "image/png"))

    get edit_push_path(push)
    assert_response :success

    # Verify data attributes contain current push values
    assert_select "div[data-knobs-default-days-value='8']"
    assert_select "div[data-knobs-default-views-value='20']"

    # Verify range fields have correct values
    assert_select "input[name='push[expire_after_days]'][value='8']"
    assert_select "input[name='push[expire_after_views]'][value='20']"
  end

  test "can update file push payload and metadata" do
    push = Push.create!(
      kind: "file",
      payload: "Original message",
      name: "Original Name",
      user: @luca,
      expire_after_days: 5,
      expire_after_views: 10
    )
    push.files.attach(fixture_file_upload("monkey.png", "image/png"))

    patch push_path(push), params: {
      push: {
        kind: "file",
        payload: "Updated message",
        name: "Updated Name",
        expire_after_days: 7,
        expire_after_views: 15
      }
    }

    assert_redirected_to preview_push_path(push)

    push.reload
    assert_equal "Updated message", push.payload
    assert_equal "Updated Name", push.name
    assert_equal 7, push.expire_after_days
    assert_equal 15, push.expire_after_views
  end

  test "can update file push files" do
    push = Push.create!(
      kind: "file",
      payload: "Message",
      user: @luca
    )
    push.files.attach(fixture_file_upload("monkey.png", "image/png"))

    initial_file_count = push.files.count
    assert_equal 1, initial_file_count

    original_filename = push.files.first.filename.to_s
    assert_equal "monkey.png", original_filename

    # Updating with new files appends them to existing ones
    patch push_path(push), params: {
      push: {
        kind: "file",
        payload: "Updated message",
        files: [fixture_file_upload("test-file.txt", "text/plain")]
      }
    }

    assert_redirected_to preview_push_path(push)

    push.reload
    # Files are appended, not replaced
    assert_equal 2, push.files.count
    filenames = push.files.map { |f| f.filename.to_s }
    assert_includes filenames, "test-file.txt"
    assert_includes filenames, "monkey.png"
    assert_equal "Updated message", push.payload
  end

  test "cannot edit file push belonging to another user" do
    other_user = users(:one)

    push = Push.create!(
      kind: "file",
      payload: "Other user's files",
      user: other_user
    )
    push.files.attach(fixture_file_upload("monkey.png", "image/png"))

    get edit_push_path(push)
    assert_redirected_to root_path

    patch push_path(push), params: {
      push: {
        kind: "file",
        payload: "Hacked message"
      }
    }
    assert_redirected_to root_path

    push.reload
    assert_equal "Other user's files", push.payload
  end

  test "cannot edit expired file push" do
    push = Push.create!(
      kind: "file",
      payload: "Expired files",
      user: @luca
    )
    push.files.attach(fixture_file_upload("monkey.png", "image/png"))

    # Manually set expired without triggering validations
    push.update_columns(expired: true, expired_on: Time.current, payload_ciphertext: nil)

    get edit_push_path(push)
    assert_redirected_to push_path(push)

    patch push_path(push), params: {
      push: {
        kind: "file",
        payload: "New message"
      }
    }
    assert_redirected_to push_path(push)
  end

  test "edit page shows update button for file push" do
    push = Push.create!(
      kind: "file",
      payload: "Test message",
      user: @luca
    )
    push.files.attach(fixture_file_upload("monkey.png", "image/png"))

    get edit_push_path(push)
    assert_response :success
    assert_select "button[type=submit]", text: /Update Push/
  end

  test "cannot exceed max file limit when updating" do
    push = Push.create!(kind: "file", user: @luca)

    # Attach files up to the limit (assume limit is 5)
    max_files = Settings.files.max_file_uploads
    max_files.times do |i|
      push.files.attach(
        io: StringIO.new("file #{i}"),
        filename: "file#{i}.txt"
      )
    end

    # Try to add one more
    patch push_path(push), params: {
      push: {
        kind: "file",
        files: [fixture_file_upload("test-file.txt")]
      }
    }

    assert_response :unprocessable_content
    assert_select "div.alert-danger",
      text: /You can only attach up to #{max_files} files/
  end

  test "can remove files when editing file push" do
    push = Push.create!(kind: "file", user: @luca)
    # Attach two files so we can delete one (last file cannot be deleted)
    push.files.attach(fixture_file_upload("monkey.png"))
    push.files.attach(fixture_file_upload("test-file.txt"))

    assert_equal 2, push.files.count
    file_to_delete = push.files.first

    # Delete the file using the correct route
    delete delete_file_push_path(push), params: {file_id: file_to_delete.id}

    assert_redirected_to edit_push_path(push)
    push.reload
    assert_equal 1, push.files.count
  end

  test "cannot delete last file from file push" do
    push = Push.create!(kind: "file", user: @luca)
    push.files.attach(fixture_file_upload("monkey.png"))

    file_to_delete = push.files.first

    delete delete_file_push_path(push), params: {file_id: file_to_delete.id}

    assert_redirected_to edit_push_path(push)
    follow_redirect!
    assert_select "div.alert-warning", text: /You cannot delete the last file/

    push.reload
    assert_equal 1, push.files.count
  end

  test "update creates audit log for file push" do
    push = Push.create!(kind: "file", payload: "https://example.com", user: @luca)

    patch push_path(push), params: {
      push: {payload: "https://updated.com"}
    }

    assert_audit_log_created(push, :edit)
  end

  test "save block is hidden when editing file push" do
    push = Push.create!(
      kind: "file",
      payload: "Test message",
      user: @luca
    )
    push.files.attach(fixture_file_upload("monkey.png", "image/png"))

    get edit_push_path(push)
    assert_response :success

    # Verify save block is not present when editing
    assert_select "div#cookie-save", false, "Save block should not be visible when editing"
  end

  test "save block is visible when creating new file push" do
    get new_push_path(tab: "files")
    assert_response :success

    # Verify save block is present when creating
    assert_select "div#cookie-save", true, "Save block should be visible when creating"
  end
end
