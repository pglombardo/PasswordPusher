class CleanUpPushesJob < ApplicationJob
  queue_as :default

  # Delete Anonymous Expired Pushes
  #
  # When a push expires, the payload is deleted but the metadata record still exists.  This
  # includes information such as creation date, audit logs, duration etc..  When the record
  # was created by an anonymous user, this data is no longer needed and we delete it (we
  # don't want it).
  #
  # If a user attempts to retrieve a secret link that doesn't exist anymore, we still show
  # the standard "This secret link has expired" message.  This strategy provides two benefits:
  #
  # 1. It hides the fact that if a secret ever exists or not (more secure)
  # 2. It allows us to delete data that we don't want
  #
  # This task will run through all expired and anonymous records and delete them entirely.
  #
  # Because of the above, expired and anonymous secret URLs still will show the same
  # expiration message
  #
  # Note: This applies to anonymous pushes.  For logged-in user records, we don't do this
  # to maintain user audit logs.
  #
  def perform(*args)
    # Log task start
    logger.info("--> #{self.class.name}: Starting...")

    counter = 0

    Push.includes(:audit_logs)
      .where(expired: true)
      .where(user_id: nil)
      .find_each do |push|
      counter += 1
      push.destroy
    end

    logger.info("  -> #{counter} total anonymous expired pushes deleted.")

    # Log completion
    logger.info("  -> #{self.class.name}: Finished.")
  end

  private

  def logger
    @logger ||= if ENV.key?("PWP_WORKER")
      # We are running inside the pwpush-worker container.  Log to STDOUT
      Logger.new($stdout)
    else
      Logger.new(Rails.root.join("log", "recurring.log"))
    end
  end
end
