# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_04_04_160008) do

  create_table "passwords", force: :cascade do |t|
    t.string "payload"
    t.integer "expire_after_days"
    t.integer "expire_after_views"
    t.boolean "expired", default: false
    t.string "url_token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.boolean "deleted", default: false
    t.boolean "first_view", default: false
    t.boolean "deletable_by_viewer"
    t.boolean "retrieval_step", default: false
    t.index ["user_id"], name: "index_passwords_on_user_id"
  end

  create_table "rails_admin_histories", force: :cascade do |t|
    t.text "message"
    t.string "username"
    t.integer "item"
    t.string "table"
    t.integer "month", limit: 2
    t.integer "year", limit: 5
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["item", "table", "month", "year"], name: "index_rails_admin_histories"
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "admin", default: false
    t.integer "failed_attempts", default: 0
    t.string "unlock_token"
    t.datetime "locked_at"
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
