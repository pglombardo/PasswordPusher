class AddUserToPassword2 < ActiveRecord::Migration
  def self.up
    unless column_exists? :passwords, :user_id
      add_column :passwords, :user_id, :integer
      add_index :passwords, :user_id
    end
  end

  def self.down
    remove_index :passwords, :user_id
    remove_column :passwords, :user_id
  end
end
