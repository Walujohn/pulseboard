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

ActiveRecord::Schema[8.1].define(version: 2026_01_17_150000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "comments", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.bigint "status_update_id", null: false
    t.datetime "updated_at", null: false
    t.index ["status_update_id"], name: "index_comments_on_status_update_id"
  end

  create_table "reactions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "emoji"
    t.bigint "status_update_id", null: false
    t.datetime "updated_at", null: false
    t.string "user_identifier"
    t.index ["status_update_id"], name: "index_reactions_on_status_update_id"
  end

  create_table "status_changes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "from_status"
    t.text "reason", comment: "Why the status changed (optional)"
    t.bigint "status_update_id", null: false
    t.string "to_status", null: false
    t.datetime "updated_at", null: false
    t.index ["status_update_id", "created_at"], name: "index_status_changes_on_status_update_id_and_created_at"
    t.index ["status_update_id"], name: "index_status_changes_on_status_update_id"
  end

  create_table "status_updates", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.integer "likes_count", default: 0, null: false
    t.string "mood"
    t.datetime "updated_at", null: false
  end

  add_foreign_key "comments", "status_updates"
  add_foreign_key "reactions", "status_updates"
  add_foreign_key "status_changes", "status_updates"
end
