class PurgeUnattachedBlobsJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "Starting purge of unattached Active Storage blobs..."
    system("bin/pwpush active_storage:purge_unattached")
    Rails.logger.info "Completed purge of unattached Active Storage blobs"
  end
end
