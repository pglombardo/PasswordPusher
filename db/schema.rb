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

ActiveRecord::Schema.define(version: 2021_08_21_082834) do

  create_table "passwords", force: :cascade do |t|
    t.text "payload", limit: 255
    t.integer "expire_after_days"
    t.integer "expire_after_views"
    t.boolean "expired", default: false
    t.string "url_token", limit: 255
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
    t.string "username", limit: 255
    t.integer "item"
    t.string "table", limit: 255
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
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "views", force: :cascade do |t|
    t.integer "password_id"
    t.string "ip", limit: 255
    t.string "user_agent", limit: 255
    t.string "referrer", limit: 255
    t.boolean "successful"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
