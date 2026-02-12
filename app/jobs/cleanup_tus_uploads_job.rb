# frozen_string_literal: true

# Deletes TUS upload temp dirs that were not finalized within the configured TTL.
# Runs when TUS uploads are enabled (temp dirs exist for both local and cloud).
class CleanupTusUploadsJob < ApplicationJob
  queue_as :default

  def perform
    return unless Settings.files.use_tus_uploads.to_s == "true"

    ttl = (Settings.files.tus_upload_ttl || 86400).to_i
    TusUploadStore.cleanup_stale!(ttl_seconds: ttl)
  end
end
