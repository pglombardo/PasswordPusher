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

ActiveRecord::Schema.define(version: 2021_12_03_124450) do

  create_table "passwords", force: :cascade do |t|
    t.text "payload_legacy"
    t.integer "expire_after_days"
    t.integer "expire_after_views"
    t.boolean "expired", default: false
    t.string "url_token"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "user_id"
    t.boolean "deleted", default: false
    t.boolean "deletable_by_viewer", default: true
    t.boolean "retrieval_step", default: false
    t.datetime "expired_on"
    t.text "note_legacy", default: ""
    t.text "payload_ciphertext", limit: 16777215
    t.text "note_ciphertext"
    t.index ["url_token"], name: "index_passwords_on_url_token", unique: true
    t.index ["user_id"], name: "index_passwords_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "admin", default: false
    t.integer "failed_attempts", default: 0
    t.string "unlock_token"
    t.datetime "locked_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
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
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "kind", default: 0
    t.integer "user_id"
  end

end
