class CreateAuditLog < ActiveRecord::Migration[7.2]
  def change
    create_table :audit_logs do |t|
      t.string :ip
      t.string :user_agent
      t.string :referrer
      t.integer :kind, null: false

      t.index :kind

      t.references :user, foreign_key: false
      t.references :push, null: false, foreign_key: true
      t.timestamps
    end
  rescue => e
    if ActiveRecord::Base.connection.adapter_name.downcase.starts_with?("mysql")
      # Attempt to resolve an issue with MariaDB: https://github.com/pglombardo/PasswordPusher/issues/3422
      # StandardError: An error has occurred, all later migrations canceled: (StandardError)
      # Column `user_id` on table `pushes` does not match column `id` on `users`, which has type `int(11)`. To resolve this issue, change the type of the `user_id` column on `pushes` to be :integer. (For example `t.integer :user_id`).
      # Original message: Mysql2::Error: Can't create table `db_name`.`pushes` (errno: 150 "Foreign key constraint is incorrectly formed")
      Rails.logger.warn("Failed to create audit_logs table: #{e}.  Attempting to create audit_logs table with integer user_id.")

      create_table :audit_logs do |t|
        t.string :ip
        t.string :user_agent
        t.string :referrer
        t.integer :kind, null: false

        t.index :kind

        t.references :user, foreign_key: false, type: :integer
        t.references :push, null: false, foreign_key: true, type: :integer
        t.timestamps
      end

    else
      raise e
    end
  end
end
