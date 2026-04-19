# frozen_string_literal: true

class CreateShareByEmails < ActiveRecord::Migration[8.1]
  def change
    create_table :share_by_emails do |t|
      t.references :audit_log, null: false, foreign_key: true
      t.text :recipients_ciphertext, null: false
      t.text :successful_sends_ciphertext
      t.text :locale_ciphertext
      t.integer :status, default: 0, null: false

      t.timestamps
    end
  end
end
