# frozen_string_literal: true

# Shared setup/teardown for tests that change TUS- and file-push-related Settings.
# Include this module and call store_tus_related_settings in setup and
# restore_tus_related_settings in teardown to avoid leaking settings between tests.
module TusUploadTestSettings
  def store_tus_related_settings
    @_tus_test_settings = {
      enable_logins: Settings.enable_logins,
      enable_file_pushes: Settings.enable_file_pushes,
      files_storage: Settings.files.storage,
      files_max_tus_upload_size: Settings.files.max_tus_upload_size,
      files_tus_upload_ttl: Settings.files.tus_upload_ttl,
      files_max_direct_upload_size: Settings.files.max_direct_upload_size,
      files_max_file_uploads: Settings.files.max_file_uploads
    }
  end

  def restore_tus_related_settings
    return unless defined?(@_tus_test_settings) && @_tus_test_settings

    Settings.enable_logins = @_tus_test_settings[:enable_logins]
    Settings.enable_file_pushes = @_tus_test_settings[:enable_file_pushes]
    Settings.files.storage = @_tus_test_settings[:files_storage]
    Settings.files.max_tus_upload_size = @_tus_test_settings[:files_max_tus_upload_size]
    Settings.files.tus_upload_ttl = @_tus_test_settings[:files_tus_upload_ttl]
    Settings.files.max_direct_upload_size = @_tus_test_settings[:files_max_direct_upload_size]
    Settings.files.max_file_uploads = @_tus_test_settings[:files_max_file_uploads]
  end
end
