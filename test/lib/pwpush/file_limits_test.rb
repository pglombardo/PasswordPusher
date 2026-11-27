# frozen_string_literal: true

require "test_helper"

class Pwpush::FileLimitsTest < ActiveSupport::TestCase
  teardown do
    Settings.reload!
  end

  test "default max file size is 100GB" do
    assert_equal 100 * (1024**3), Pwpush::FileLimits.max_file_size_bytes
    assert Pwpush::FileLimits.limited?
  end

  test "parses human file size strings" do
    assert_equal 256 * (1024**2), Pwpush::FileLimits.parse_file_size("256MB")
    assert_equal 5 * (1024**3), Pwpush::FileLimits.parse_file_size("5 GB")
    assert_equal 10, Pwpush::FileLimits.parse_file_size(10)
  end

  test "0, blank, and unlimited disable the cap" do
    Settings.files.max_file_size = 0
    assert_nil Pwpush::FileLimits.max_file_size_bytes
    assert_not Pwpush::FileLimits.limited?
    assert Pwpush::FileLimits.allowed_byte_size?(10.gigabytes)

    Settings.files.max_file_size = "unlimited"
    assert_nil Pwpush::FileLimits.max_file_size_bytes
  end

  test "allowed_byte_size? enforces the configured cap" do
    Settings.files.max_file_size = "1MB"
    assert Pwpush::FileLimits.allowed_byte_size?(1024)
    assert_not Pwpush::FileLimits.allowed_byte_size?(2.megabytes)
  end

  test "too_large_message is localized with the human size" do
    Settings.files.max_file_size = "10MB"
    message = Pwpush::FileLimits.too_large_message(filename: "movie.mp4")
    assert_includes message, "movie.mp4"
    assert_includes message, "10MB"
  end

  test "default download URL expiry is 5 minutes" do
    assert_equal 5.minutes, Pwpush::FileLimits.blob_url_expires_in
    assert_equal "5:00", Pwpush::FileLimits.blob_url_expires_in_clock
  end

  test "default direct upload URL expiry is 1 hour" do
    assert_equal 1.hour, Pwpush::FileLimits.direct_upload_url_expires_in
  end

  test "parses duration strings from settings" do
    Settings.files.blob_urls_expire_in = "10 minutes"
    Settings.files.direct_upload_urls_expire_in = "2 hours"
    assert_equal 10.minutes, Pwpush::FileLimits.blob_url_expires_in
    assert_equal 2.hours, Pwpush::FileLimits.direct_upload_url_expires_in
    assert_equal "10:00", Pwpush::FileLimits.blob_url_expires_in_clock
  end

  test "byte_size_for resolves uploaded files, blobs, and signed blob ids" do
    upload = Rack::Test::UploadedFile.new(file_fixture("test-file.txt"), "text/plain")
    assert_equal upload.size, Pwpush::FileLimits.byte_size_for(upload)

    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("hello"),
      filename: "hello.txt",
      content_type: "text/plain"
    )
    assert_equal blob.byte_size, Pwpush::FileLimits.byte_size_for(blob)
    assert_equal blob.byte_size, Pwpush::FileLimits.byte_size_for(blob.signed_id)
    assert_equal "hello.txt", Pwpush::FileLimits.filename_for(blob.signed_id)
    assert_nil Pwpush::FileLimits.byte_size_for("not-a-signed-id")
  end
end
