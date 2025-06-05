class CreatePushes < ActiveRecord::Migration[7.2]
  def change
    create_table(:pushes) do |t|
      t.integer :kind, null: false
      t.integer :expire_after_days
      t.integer :expire_after_views
      t.boolean :expired, default: false
      t.string :url_token
      t.boolean :deletable_by_viewer, default: true
      t.boolean :retrieval_step, default: false
      t.datetime :expired_on
      t.text :payload_ciphertext, limit: 16.megabytes - 1
      t.text :note_ciphertext
      t.text :passphrase_ciphertext, limit: 2048
      t.string :name

      t.index [:url_token], unique: true
      t.references :user, foreign_key: true
      t.timestamps
    end
  rescue => e
    if ActiveRecord::Base.connection.adapter_name.downcase.starts_with?("mysql")
      # Attempt to resolve an issue with MariaDB: https://github.com/pglombardo/PasswordPusher/issues/3422
      # StandardError: An error has occurred, all later migrations canceled: (StandardError)
      # Column `user_id` on table `pushes` does not match column `id` on `users`, which has type `int(11)`. To resolve this issue, change the type of the `user_id` column on `pushes` to be :integer. (For example `t.integer :user_id`).
      # Original message: Mysql2::Error: Can't create table `db_name`.`pushes` (errno: 150 "Foreign key constraint is incorrectly formed")
      Rails.logger.warn("Failed to create pushes table: #{e}.  Attempting to create pushes table with integer user_id.")

      create_table(:pushes) do |t|
        t.integer :kind, null: false
        t.integer :expire_after_days
        t.integer :expire_after_views
        t.boolean :expired, default: false
        t.string :url_token
        t.boolean :deletable_by_viewer, default: true
        t.boolean :retrieval_step, default: false
        t.datetime :expired_on
        t.text :payload_ciphertext, limit: 16.megabytes - 1
        t.text :note_ciphertext
        t.text :passphrase_ciphertext, limit: 2048
        t.string :name

        t.index [:url_token], unique: true
        t.references :user, foreign_key: true, type: :integer
        t.timestamps
      end

    else
      raise e
    end
  end
end
