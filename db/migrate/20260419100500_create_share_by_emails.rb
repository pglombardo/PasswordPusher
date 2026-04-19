class CreateShareByEmails < ActiveRecord::Migration[8.1]
  def change
    create_table :share_by_emails do |t|
      t.references :audit_log, null: false, foreign_key: true
      t.text :recipients, null: false
      t.text :successful_sends
      t.string :locale
      t.integer :status, default: 0, null: false

      t.timestamps
    end
  end
end
