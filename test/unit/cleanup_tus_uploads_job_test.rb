# frozen_string_literal: true

require "test_helper"

class CleanupTusUploadsJobTest < ActiveSupport::TestCase
  include TusUploadTestSettings

  setup do
    store_tus_related_settings
  end

  teardown do
    restore_tus_related_settings
  end

  test "perform does nothing when file pushes disabled" do
    Settings.enable_file_pushes = false
    # Create a stale upload; if job ran cleanup it would be removed
    store = TusUploadStore.new(TusUploadStore.generate_id)
    store.create!(upload_length: 1)
    meta_path = store.meta_path
    File.write(meta_path, {
      "upload_length" => 1,
      "upload_offset" => 0,
      "filename" => nil,
      "content_type" => nil,
      "created_at" => (Time.current - 86400 * 2).utc.iso8601
    }.to_json)
    path = store.path

    CleanupTusUploadsJob.perform_now

    assert File.exist?(path), "Stale upload should remain when file pushes disabled"
  ensure
    FileUtils.rm_rf(path) if path && File.exist?(path)
  end

  test "perform removes stale uploads when file pushes enabled" do
    Settings.enable_file_pushes = true
    Settings.files.tus_upload_ttl = 86400
    store = TusUploadStore.new(TusUploadStore.generate_id)
    store.create!(upload_length: 1)
    meta_path = store.meta_path
    File.write(meta_path, {
      "upload_length" => 1,
      "upload_offset" => 0,
      "filename" => nil,
      "content_type" => nil,
      "created_at" => (Time.current - 86400 * 2).utc.iso8601
    }.to_json)
    path = store.path

    CleanupTusUploadsJob.perform_now

    assert_not File.exist?(path), "Stale upload should be removed when file pushes enabled"
  end

  test "perform uses default TTL when tus_upload_ttl is nil and removes stale uploads" do
    Settings.enable_file_pushes = true
    Settings.files.tus_upload_ttl = nil
    store = TusUploadStore.new(TusUploadStore.generate_id)
    store.create!(upload_length: 1)
    meta_path = store.meta_path
    File.write(meta_path, {
      "upload_length" => 1,
      "upload_offset" => 0,
      "filename" => nil,
      "content_type" => nil,
      "created_at" => (Time.current - 86400 * 2).utc.iso8601
    }.to_json)
    path = store.path

    CleanupTusUploadsJob.perform_now

    assert_not File.exist?(path),
      "Stale upload should be removed when tus_upload_ttl is nil (default 86400 used)"
  end

  test "perform runs without error when file pushes enabled and no uploads" do
    Settings.enable_file_pushes = true
    assert_nothing_raised do
      CleanupTusUploadsJob.perform_now
    end
  end

  test "cleanup_tus_uploads is scheduled in recurring config" do
    recurring_path = Rails.root.join("config/recurring.yml")
    skip "config/recurring.yml not found" unless recurring_path.exist?
    config = YAML.load_file(recurring_path)
    %w[production development].each do |env|
      next unless config[env]
      task = config[env]["cleanup_tus_uploads"]
      assert task, "cleanup_tus_uploads should be defined in config/recurring.yml for #{env}"
      assert_equal "CleanupTusUploadsJob", task["class"], "cleanup_tus_uploads should use CleanupTusUploadsJob in #{env}"
      assert task["schedule"].present?, "cleanup_tus_uploads should have a schedule in #{env}"
    end
  end
end
