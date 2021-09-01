class DropUnusedTables < ActiveRecord::Migration[6.1]
  # 2021-09-01 The Users table and RailsAdminHistories have never been used.  In production
  # on pwpush.com, there are zero records in these tables.  Now that we are re-adding logging,
  # we still start from scratch as the Users table was created in 2012!
  def up 
    drop_table :Users
    drop_table :rails_admin_histories
  end

  def down
    # We'll just recreate the tables on rollback since they were empty anyways
    # These were copied from the original creation migrations
    
    create_table(:users) do |t|
      t.string :email,              :null => false, :default => ""
      t.string :encrypted_password, :null => false, :default => ""
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at
      t.integer  :sign_in_count, :default => 0
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip
      t.timestamps
    end

    create_table(:rails_admin_histories) do |t|
      t.text :message # title, name, or object_id
      t.string :username
      t.integer :item
      t.string :table
      t.integer :month, :limit => 2
      t.integer :year, :limit => 5
      t.timestamps
   end
  end
end
