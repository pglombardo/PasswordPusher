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

ActiveRecord::Schema.define(version: 2021_09_01_122057) do

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
