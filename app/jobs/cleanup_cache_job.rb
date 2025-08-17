class CleanupCacheJob < ApplicationJob
  queue_as :default

  def perform
    logger.info("--> #{self.class.name}: Starting cache cleanup...")

    # Clean up main Rails cache
    cleanup_cache_directory(Rails.root.join("tmp", "cache"))

    # Clean up Rack::Attack cache
    cleanup_cache_directory(Rails.root.join("tmp", "rack_attack_cache"))

    logger.info("  -> #{self.class.name}: Cache cleanup completed.")
  end

  private

  def cleanup_cache_directory(cache_dir)
    return unless Dir.exist?(cache_dir)

    # Safety check: ensure the cache directory is within the tmp directory
    tmp_root = Rails.root.join("tmp").to_s
    unless cache_dir.to_s.start_with?(tmp_root)
      logger.error("  -> SAFETY VIOLATION: Cache directory #{cache_dir} is not within #{tmp_root}. Skipping cleanup.")
      return
    end

    logger.info("  -> Cleaning up cache directory: #{cache_dir}")

    # Remove files older than 24 hours
    cutoff_time = 24.hours.ago

    Dir.glob(File.join(cache_dir, "**", "*")).each do |file|
      next unless File.file?(file)

      if File.mtime(file) < cutoff_time
        begin
          File.delete(file)
        rescue => e
          logger.warn("  -> Failed to delete cache file #{file}: #{e.message}")
        end
      end
    end
  end

  def logger
    @logger ||= if ENV.key?("PWP_WORKER")
      # We are running inside the pwpush-worker container. Log to STDOUT
      Logger.new($stdout)
    else
      Logger.new(Rails.root.join("log", "recurring.log"))
    end
  end
end
