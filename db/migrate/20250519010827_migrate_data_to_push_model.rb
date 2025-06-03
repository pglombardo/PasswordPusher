class MigrateDataToPushModel < ActiveRecord::Migration[7.2]
  def up
    # This originally contained data migration code but it was moved to config/initializers/migrate_data.rb
    # Reasons: Docker timeouts and health checks would kill the container before the data migration was complete
    # This migration is now only used to create the data_migration_statuses table

    create_table :data_migration_statuses do |t|
      t.string :name, null: false
      t.boolean :completed, default: false
      t.datetime :completed_at
      t.timestamps
    end
    add_index :data_migration_statuses, :name, unique: true
  end

  def down
    drop_table :data_migration_statuses
  end
end
