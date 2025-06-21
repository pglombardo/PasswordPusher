class PurgeExpiredPushesJob < ApplicationJob
  queue_as :default

  # Delete Expired Pushes After Duration
  #
  # When a push expires, the payload is deleted but the metadata record still exists.  This
  # includes information such as creation date, audit logs, duration etc..  If purge_after setting
  # is set to a duration, this job will delete expired pushes and their audit logs after
  # that duration.
  #
  # If a user attempts to retrieve a secret link that doesn't exist anymore, we still show
  # the standard "This secret link has expired" message.  This strategy provides two benefits:
  #
  # 1. It hides the fact that if a secret ever exists or not (more secure)
  # 2. It allows us to delete data that we don't want
  #
  # This task will run through all records expired more than purge_after ago and delete them entirely.
  #
  # Because of the above, expired secret URLs still will show the same
  # expiration message.
  #
  def perform(*args)
    return if Settings.purge_after == "disabled"

    # Log task start
    logger.info("--> #{self.class.name}: Starting...")

    counter = 0

    Push.where(expired: true)
      .where("expired_on < ?", Time.current - to_duration(Settings.purge_after))
      .find_each do |push|
      counter += 1
      push.destroy
    end

    logger.info("  -> #{counter} expired pushes older than #{Settings.purge_after} ago have been purged.")

    # Log completion
    logger.info("  -> #{self.class.name}: Finished.")
  end

  private

  # Convert a string duration to a time duration
  def to_duration(str)
    str.to_s.strip.split(" ").then { |quantity, unit| quantity.to_i.send(unit.downcase.to_sym) }
  end

  def logger
    @logger ||= if ENV.key?("PWP_WORKER")
      # We are running inside the pwpush-worker container.  Log to STDOUT
      Logger.new($stdout)
    else
      Logger.new(Rails.root.join("log", "recurring.log"))
    end
  end
end
