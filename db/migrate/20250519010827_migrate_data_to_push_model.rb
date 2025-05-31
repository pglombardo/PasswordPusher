class MigrateDataToPushModel < ActiveRecord::Migration[7.2]
  def up
    # Create migration status table if it doesn't exist
    unless table_exists?(:data_migration_statuses)
      create_table :data_migration_statuses do |t|
        t.string :name, null: false
        t.boolean :completed, default: false
        t.datetime :completed_at
        t.timestamps
      end
      add_index :data_migration_statuses, :name, unique: true
    end

    # Create initial status record
    DataMigrationStatus.create_or_find_by(name: "push_model_migration").update!(
      completed: false,
      completed_at: nil
    )

    # Start the background data migration job
    MigrateDataToPushModelJob.perform_later
  end

  def down
    attach_files_to_old_records
    remove_all_audit_logs
    remove_all_pushes
    drop_table :data_migration_statuses if table_exists?(:data_migration_statuses)
  end

  private

  def remove_all_pushes
    Push.delete_all
  end

  def remove_all_audit_logs
    AuditLog.delete_all
  end

  def attach_files_to_old_records
    Push.where(kind: Push.kinds[:file]).find_each do |push|
      file_push = FilePush.find_by(url_token: push.url_token)
      if file_push
        push.files.attachments.each do |attachment|
          attachment.update!(record_type: FilePush.name, record: file_push)
        end
      else
        puts "Warning: FilePush not found for push #{push.id} (url_token: #{push.url_token}) during rollback. Cannot reattach files."
      end
    rescue => e
      # Consider if this error should halt the rollback. Currently, it logs and continues.
      puts "Error reverting attachments for push #{push.id} (url_token: #{push.url_token}): #{e.message}"
    end
  end
end
