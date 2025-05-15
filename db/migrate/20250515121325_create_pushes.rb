class CreatePushes < ActiveRecord::Migration[7.2]
  def change
    create_table(:pushes) do |t|
      t.integer :kind
      t.integer :expire_after_days
      t.integer :expire_after_views
      t.boolean :expired, default: false
      t.string :url_token
      t.boolean :deleted, default: false
      t.boolean :deletable_by_viewer, default: true
      t.boolean :retrieval_step, default: false
      t.datetime :expired_on
      t.text :payload_ciphertext, limit: 16.megabytes - 1
      t.text :note_ciphertext
      t.text :passphrase_ciphertext, limit: 2048
      t.string :name
      
      t.index [:url_token], unique: true
      t.references :user, foreign_key: true
      t.timestamps
    end
  end
end
