class CreatePasswords < ActiveRecord::Migration
  def change
    create_table :passwords do |t|
      t.string :payload
      t.integer :expire_after_days
      t.integer :expire_after_views
      t.integer :views, :default => 0
      t.timestamps
    end
  end
end
