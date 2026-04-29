# frozen_string_literal: true

class CreateNotifyByEmails < ActiveRecord::Migration[8.1]
  def change
    create_table :notify_by_emails do |t|
      t.references :audit_log, null: false, foreign_key: true
      t.text :recipients_ciphertext, null: false
      t.integer :recipients_count, default: 0, null: false
      t.text :successful_sends_ciphertext
      t.string :locale_ciphertext
      t.integer :status, default: 0, null: false

      t.timestamps
    end
  end
end
