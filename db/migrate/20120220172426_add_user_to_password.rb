# frozen_string_literal: true

class AddUserToPassword < ActiveRecord::Migration[4.2]
  def self.up
    add_column :passwords, :user_id, :integer
    add_index :passwords, :user_id
  end

  def self.down
    remove_index :passwords, :user_id
    remove_column :passwords, :user_id
  end
end
