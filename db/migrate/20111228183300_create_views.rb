# frozen_string_literal: true

class CreateViews < ActiveRecord::Migration[4.2]
  def self.up
    create_table :views do |t|
      t.integer :password_id
      t.string :ip
      t.string :user_agent
      t.string :referrer
      t.boolean :successful
      t.timestamps
    end
  end

  def self.down
    drop_table :views
  end
end
