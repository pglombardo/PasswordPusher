class DropLegacyModels < ActiveRecord::Migration[7.2]
  def up
    # Check if data migration is complete
    if DataMigrationStatus.find_by(name: "push_model_migration")&.completed? ||
        ActiveRecord::Base.connection.execute(<<-SQL).first["total_count"] == 0
         SELECT (
           (SELECT COUNT(*) FROM passwords) +
           (SELECT COUNT(*) FROM urls) +
           (SELECT COUNT(*) FROM file_pushes)
         ) as total_count
        SQL
      drop_table :passwords, force: :cascade
      drop_table :urls, force: :cascade
      drop_table :file_pushes, force: :cascade
    else
      error_message = "Data migration not completed. Please run v1.56.3 first and allow the data migration to complete. Then update to this version. See https://github.com/pglombardo/PasswordPusher/releases/tag/v1.56.0 for more information."
      Rails.logger.error("Migration failed: #{error_message}")
      raise ActiveRecord::MigrationError, error_message
    end
  end

  def down
    # We can't recreate these tables as they were since they've been migrated to the new push model
    raise ActiveRecord::IrreversibleMigration, "This migration is irreversible as it drops legacy tables that have been migrated to the new push model."
  end
end
