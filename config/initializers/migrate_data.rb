Rails.application.config.after_initialize do
  # Only proceed if the data_migration_statuses table exists
  if ActiveRecord::Base.connection.table_exists?(:data_migration_statuses)
    # If the Push model data migration has not been run, run it
    status = DataMigrationStatus.find_by(name: "push_model_migration")
    if status.nil? || !status.completed?
      if (Password.count + FilePush.count + Url.count) > 0
        MigrateDataToPushModelJob.perform_later
      else
        DataMigrationStatus.create_or_find_by(name: "push_model_migration").update!(
          completed: true,
          completed_at: Time.current
        )
      end
    end
  end
end
