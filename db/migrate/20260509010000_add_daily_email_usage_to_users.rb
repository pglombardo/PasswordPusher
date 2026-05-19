# frozen_string_literal: true

class AddDailyEmailUsageToUsers < ActiveRecord::Migration[8.1]
  def change
    change_table :users, bulk: true do |t|
      t.integer :email_sent_count, default: 0, null: false
      t.datetime :email_sent_count_reset_at
    end
  end
end
