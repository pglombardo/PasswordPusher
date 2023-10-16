# frozen_string_literal: true

class DropUnusedTables < ActiveRecord::Migration[6.1]
  def up
    drop_table :rails_admin_histories
  end

  def down
    # We'll just recreate the table on rollback since they were empty anyways
    # Copied from the original creation migrations
    create_table(:rails_admin_histories) do |t|
      t.text :message # title, name, or object_id
      t.string :username
      t.integer :item
      t.string :table
      t.integer :month, limit: 2
      t.integer :year, limit: 5
      t.timestamps
    end
  end
end
