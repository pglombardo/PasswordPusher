# frozen_string_literal: true

class CreatePasswords < ActiveRecord::Migration[4.2]
  def change
    create_table :passwords do |t|
      t.string :payload
      t.integer :expire_after_days
      t.integer :expire_after_views
      t.boolean :expired, default: false
      t.string :url_token
      t.timestamps
    end
  end
end
