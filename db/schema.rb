# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2024_07_19_081651) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.integer "record_id", null: false
    t.integer "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.integer "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", precision: nil, null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.integer "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "file_pushes", force: :cascade do |t|
    t.integer "expire_after_days"
    t.integer "expire_after_views"
    t.boolean "expired", default: false
    t.string "url_token"
    t.integer "user_id"
    t.boolean "deleted", default: false
    t.boolean "deletable_by_viewer", default: true
    t.boolean "retrieval_step", default: false
    t.datetime "expired_on"
    t.text "payload_ciphertext", limit: 16777215
    t.text "text", limit: 16777215
    t.text "note_ciphertext"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "passphrase_ciphertext", limit: 2048
    t.index ["url_token"], name: "index_file_pushes_on_url_token", unique: true
    t.index ["user_id"], name: "index_file_pushes_on_user_id"
  end

  create_table "passwords", force: :cascade do |t|
    t.integer "expire_after_days"
    t.integer "expire_after_views"
    t.boolean "expired", default: false
    t.string "url_token"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "user_id"
    t.boolean "deleted", default: false
    t.boolean "deletable_by_viewer", default: true
    t.boolean "retrieval_step", default: false
    t.datetime "expired_on", precision: nil
    t.text "payload_ciphertext", limit: 16777215
    t.text "note_ciphertext"
    t.text "passphrase_ciphertext", limit: 2048
    t.index ["url_token"], name: "index_passwords_on_url_token", unique: true
    t.index ["user_id"], name: "index_passwords_on_user_id"
  end

  create_table "urls", force: :cascade do |t|
    t.integer "expire_after_days"
    t.integer "expire_after_views"
    t.boolean "expired", default: false
    t.string "url_token"
    t.integer "user_id"
    t.boolean "deleted", default: false
    t.boolean "retrieval_step", default: false
    t.datetime "expired_on"
    t.text "payload_ciphertext", limit: 2097152
    t.text "text", limit: 2097152
    t.text "note_ciphertext"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "passphrase_ciphertext", limit: 2048
    t.index ["url_token"], name: "index_urls_on_url_token", unique: true
    t.index ["user_id"], name: "index_urls_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.integer "sign_in_count", default: 0
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.boolean "admin", default: false
    t.integer "failed_attempts", default: 0
    t.string "unlock_token"
    t.datetime "locked_at", precision: nil
    t.string "confirmation_token"
    t.datetime "confirmed_at", precision: nil
    t.datetime "confirmation_sent_at", precision: nil
    t.string "unconfirmed_email"
    t.string "authentication_token", limit: 30
    t.string "preferred_language"
    t.index ["authentication_token"], name: "index_users_on_authentication_token", unique: true
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  create_table "views", force: :cascade do |t|
    t.integer "password_id"
    t.string "ip"
    t.string "user_agent"
    t.string "referrer"
    t.boolean "successful"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "kind", default: 0
    t.integer "user_id"
    t.integer "file_push_id"
    t.integer "url_id"
    t.index ["file_push_id"], name: "index_views_on_file_push_id"
    t.index ["kind"], name: "index_views_on_kind"
    t.index ["password_id"], name: "index_views_on_password_id"
    t.index ["successful"], name: "index_views_on_successful"
    t.index ["url_id"], name: "index_views_on_url_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
end
