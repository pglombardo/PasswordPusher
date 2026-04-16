# frozen_string_literal: true

require "test_helper"

class ApplicationHelperTusUploadTest < ActionView::TestCase
  include ApplicationHelper
  include TusUploadTestSettings

  setup do
    store_tus_related_settings
  end

  teardown do
    restore_tus_related_settings
    ENV.delete("FORCE_SSL")
  end

  test "tus_uploads_enabled? returns false when logins disabled" do
    Settings.disable_logins = true
    Settings.enable_file_pushes = true
    assert_not tus_uploads_enabled?
  end

  test "tus_uploads_enabled? returns false when file pushes disabled" do
    Settings.disable_logins = false
    Settings.enable_file_pushes = false
    assert_not tus_uploads_enabled?
  end

  test "tus_uploads_enabled? returns true when logins and file pushes enabled" do
    Settings.disable_logins = false
    Settings.enable_file_pushes = true
    assert tus_uploads_enabled?
  end

  test "tus_uploads_url returns uploads_path" do
    Rails.application.reload_routes!
    url = tus_uploads_url
    assert url.present?
    assert_equal Rails.application.routes.url_helpers.uploads_path, url
  end

  test "parse_human_size parses human-friendly sizes to bytes" do
    fallback = 2 * 1024 * 1024
    assert_equal 50 * 1024 * 1024, parse_human_size("50 MB")
    assert_equal 2 * 1024 * 1024, parse_human_size("2 MB")
    assert_equal 1024**3, parse_human_size("1 GB")
    assert_equal 100 * 1024, parse_human_size("100 KB")
    assert_equal 64, parse_human_size("64 B")
    assert_equal 50 * 1024 * 1024, parse_human_size("50mb")
    assert_equal 50 * 1024 * 1024, parse_human_size("50   mb")
    assert_equal 5, parse_human_size(5)
    assert_equal 5, parse_human_size("5")
    assert_equal fallback, parse_human_size("")
    assert_equal fallback, parse_human_size(nil)

    assert_equal fallback, parse_human_size("1 ZB"), "unknown unit must use fallback"
    assert_equal fallback, parse_human_size("50 XB")
    assert_equal fallback, parse_human_size("12.4")
    assert_equal fallback, parse_human_size("not a size")
    assert_equal fallback, parse_human_size("MB 50")
    assert_equal fallback, parse_human_size("50 MB trailing"), "no extra tokens allowed"
  end

  test "tus_chunk_size_bytes returns bytes from Settings.files.tus_chunk_size" do
    Settings.files.tus_chunk_size = "50 MB"
    assert_equal 50 * 1024 * 1024, tus_chunk_size_bytes
  end

  test "max_tus_upload_size_bytes returns bytes from Settings.files.max_tus_upload_size" do
    Settings.files.max_tus_upload_size = "100 GB"
    assert_equal 100 * 1024 * 1024 * 1024, max_tus_upload_size_bytes
    Settings.files.max_tus_upload_size = 107374182400
    assert_equal 107374182400, max_tus_upload_size_bytes
  end

  test "max_direct_upload_size_bytes returns bytes from Settings.files.max_direct_upload_size" do
    Settings.files.max_direct_upload_size = "100 MB"
    assert_equal 100 * 1024 * 1024, max_direct_upload_size_bytes
    Settings.files.max_direct_upload_size = 104857600
    assert_equal 104857600, max_direct_upload_size_bytes
  end
end
