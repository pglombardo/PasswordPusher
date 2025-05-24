class CreateAuditLog < ActiveRecord::Migration[7.2]
  def change
    create_table :audit_logs do |t|
      t.string :ip
      t.string :user_agent
      t.string :referrer
      t.integer :kind

      t.index :kind

      t.references :user, foreign_key: false
      t.references :push, null: false, foreign_key: true
      t.timestamps
    end
  end
end
