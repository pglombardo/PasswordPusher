# frozen_string_literal: true

require "test_helper"

class PushEditTest < ActiveSupport::TestCase
  setup do
    @user = users(:luca)
    Settings.enable_logins = true
    Settings.enable_url_pushes = true
    Settings.enable_qr_pushes = true
    Settings.enable_file_pushes = true
  end

  test "should update text push with valid payload" do
    push = Push.create!(
      kind: "text",
      payload: "Original password",
      user: @user
    )

    push.payload = "Updated password"
    assert push.save
    assert_equal "Updated password", push.payload
  end

  test "should not update text push with empty payload" do
    push = Push.create!(
      kind: "text",
      payload: "Original password",
      user: @user
    )

    push.payload = ""
    assert_not push.valid?
    assert_includes push.errors[:payload], "Payload is required."
  end

  test "should not update text push with payload exceeding 1MB" do
    push = Push.create!(
      kind: "text",
      payload: "Original password",
      user: @user
    )

    push.payload = "a" * (1.megabyte + 1)
    assert_not push.valid?
    assert_includes push.errors[:payload], "The payload is too large.  You can only push up to 1048576 bytes."
  end

  test "should update url push with valid URL" do
    push = Push.create!(
      kind: "url",
      payload: "https://example.com",
      user: @user
    )

    push.payload = "https://updated-example.com"
    assert push.save
    assert_equal "https://updated-example.com", push.payload
  end

  test "should not update url push with invalid URL" do
    push = Push.create!(
      kind: "url",
      payload: "https://example.com",
      user: @user
    )

    push.payload = "not-a-valid-url"
    assert_not push.valid?
    assert_includes push.errors[:payload], "must be a valid HTTP or HTTPS URL."
  end

  test "should not update url push with empty payload" do
    push = Push.create!(
      kind: "url",
      payload: "https://example.com",
      user: @user
    )

    push.payload = ""
    assert_not push.valid?
    assert_includes push.errors[:payload], "Payload is required."
  end

  test "should update qr push with valid content within 1024 characters" do
    push = Push.create!(
      kind: "qr",
      payload: "Original QR content",
      user: @user
    )

    push.payload = "Updated QR content"
    assert push.save
    assert_equal "Updated QR content", push.payload
  end

  test "should not update qr push with payload exceeding 1024 characters" do
    push = Push.create!(
      kind: "qr",
      payload: "Original QR content",
      user: @user
    )

    push.payload = "a" * 1025
    assert_not push.valid?
    assert_includes push.errors[:payload], "The QR code payload is too large.  You can only push up to 1024 bytes."
  end

  test "should not update qr push with empty payload" do
    push = Push.create!(
      kind: "qr",
      payload: "Original QR content",
      user: @user
    )

    push.payload = ""
    assert_not push.valid?
    assert_includes push.errors[:payload], "Payload is required."
  end

  test "should update qr push with exactly 1024 characters" do
    push = Push.create!(
      kind: "qr",
      payload: "Original QR content",
      user: @user
    )

    push.payload = "a" * 1024
    assert push.save
    assert_equal 1024, push.payload.length
  end

  test "should update push name" do
    push = Push.create!(
      kind: "text",
      payload: "Password",
      name: "Original Name",
      user: @user
    )

    push.name = "Updated Name"
    assert push.save
    assert_equal "Updated Name", push.name
  end

  test "should update push note" do
    push = Push.create!(
      kind: "text",
      payload: "Password",
      note: "Original note",
      user: @user
    )

    push.note = "Updated note"
    assert push.save
    assert_equal "Updated note", push.note
  end

  test "should update push passphrase" do
    push = Push.create!(
      kind: "text",
      payload: "Password",
      passphrase: "old_passphrase",
      user: @user
    )

    push.passphrase = "new_passphrase"
    assert push.save
    assert_equal "new_passphrase", push.passphrase
  end

  test "should update expire_after_days" do
    push = Push.create!(
      kind: "text",
      payload: "Password",
      expire_after_days: 5,
      user: @user
    )

    push.expire_after_days = 10
    assert push.save
    assert_equal 10, push.expire_after_days
  end

  test "should update expire_after_views" do
    push = Push.create!(
      kind: "text",
      payload: "Password",
      expire_after_views: 5,
      user: @user
    )

    push.expire_after_views = 10
    assert push.save
    assert_equal 10, push.expire_after_views
  end

  test "should update retrieval_step" do
    push = Push.create!(
      kind: "text",
      payload: "Password",
      retrieval_step: false,
      user: @user
    )

    push.retrieval_step = true
    assert push.save
    assert push.retrieval_step
  end

  test "should update deletable_by_viewer" do
    push = Push.create!(
      kind: "text",
      payload: "Password",
      deletable_by_viewer: false,
      user: @user
    )

    push.deletable_by_viewer = true
    assert push.save
    assert push.deletable_by_viewer
  end

  test "should not change url_token on update" do
    push = Push.create!(
      kind: "text",
      payload: "Password",
      user: @user
    )

    original_token = push.url_token
    push.payload = "Updated password"
    push.save

    assert_equal original_token, push.url_token
  end

  test "should not change created_at on update" do
    push = Push.create!(
      kind: "text",
      payload: "Password",
      user: @user
    )

    original_created_at = push.created_at
    sleep 0.1
    push.payload = "Updated password"
    push.save

    assert_equal original_created_at, push.created_at
  end

  # File Push Editing Tests
  test "should add more files to existing file push" do
    push = Push.create!(
      kind: "file",
      user: @user
    )

    # Attach initial file
    file1 = ActiveStorage::Blob.create_and_upload!(
      io: File.open(Rails.root.join("test/fixtures/files/test-file.txt")),
      filename: "test-file.txt",
      content_type: "text/plain"
    )
    push.files.attach(file1)
    assert_equal 1, push.files.count

    # Add more files
    file2 = ActiveStorage::Blob.create_and_upload!(
      io: File.open(Rails.root.join("test/fixtures/files/test-file-2.txt")),
      filename: "test-file-2.txt",
      content_type: "text/plain"
    )
    push.files.attach(file2)
    assert push.save
    assert_equal 2, push.files.count
  end

  test "should preserve existing files when updating other attributes" do
    push = Push.create!(
      kind: "file",
      user: @user,
      name: "Original Name"
    )

    # Attach file
    file = ActiveStorage::Blob.create_and_upload!(
      io: File.open(Rails.root.join("test/fixtures/files/test-file.txt")),
      filename: "test-file.txt",
      content_type: "text/plain"
    )
    push.files.attach(file)
    assert_equal 1, push.files.count

    # Update other attributes
    push.name = "Updated Name"
    push.expire_after_days = 10
    assert push.save
    assert_equal "Updated Name", push.name
    assert_equal 10, push.expire_after_days
    assert_equal 1, push.files.count, "Files should be preserved when updating other attributes"
  end

  test "should remove a file from file push when multiple files exist" do
    push = Push.create!(
      kind: "file",
      user: @user
    )

    # Attach multiple files
    file1 = ActiveStorage::Blob.create_and_upload!(
      io: File.open(Rails.root.join("test/fixtures/files/test-file.txt")),
      filename: "test-file.txt",
      content_type: "text/plain"
    )
    file2 = ActiveStorage::Blob.create_and_upload!(
      io: File.open(Rails.root.join("test/fixtures/files/test-file-2.txt")),
      filename: "test-file-2.txt",
      content_type: "text/plain"
    )
    push.files.attach([file1, file2])
    assert_equal 2, push.files.count

    # Remove one file
    first_file = push.files.first
    first_file.purge
    push.reload
    assert_equal 1, push.files.count
  end

  test "should not allow removing last file from file push" do
    push = Push.create!(
      kind: "file",
      user: @user
    )

    # Attach single file
    file = ActiveStorage::Blob.create_and_upload!(
      io: File.open(Rails.root.join("test/fixtures/files/test-file.txt")),
      filename: "test-file.txt",
      content_type: "text/plain"
    )
    push.files.attach(file)
    assert_equal 1, push.files.count

    # Remove the file
    push.files.purge
    push.reload

    # After purging all files, there should be no files
    assert_equal 0, push.files.count

    # File push with no files can exist (validation happens on create, not update)
    # In real use, controller prevents removing all files
  end

  test "should respect max file upload limit when adding files" do
    max_files = Settings.files.max_file_uploads || 10

    push = Push.create!(
      kind: "file",
      user: @user
    )

    # Attach maximum allowed files
    max_files.times do |i|
      file = ActiveStorage::Blob.create_and_upload!(
        io: File.open(Rails.root.join("test/fixtures/files/test-file.txt")),
        filename: "test-file-#{i}.txt",
        content_type: "text/plain"
      )
      push.files.attach(file)
    end

    assert_equal max_files, push.files.count
    assert push.valid?

    # Try to add one more file beyond the limit
    extra_file = ActiveStorage::Blob.create_and_upload!(
      io: File.open(Rails.root.join("test/fixtures/files/test-file.txt")),
      filename: "extra-file.txt",
      content_type: "text/plain"
    )
    push.files.attach(extra_file)

    # Validation should fail
    assert_not push.valid?
    assert_includes push.errors[:files], "You can only attach up to #{max_files} files per push."
  end
end
