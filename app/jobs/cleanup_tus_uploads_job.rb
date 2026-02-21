# frozen_string_literal: true

# Deletes TUS upload temp dirs that were not finalized within the configured TTL.
class CleanupTusUploadsJob < ApplicationJob
  queue_as :default

  def perform
    return unless Settings.enable_file_pushes

    ttl = (Settings.files.tus_upload_ttl || 86400).to_i
    TusUploadStore.cleanup_stale!(ttl_seconds: ttl)
  end
end
