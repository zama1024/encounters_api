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

ActiveRecord::Schema[7.0].define(version: 2026_02_20_091500) do
  create_table "api_keys", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "token_digest", null: false
    t.string "key_name"
    t.datetime "revoked_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token_digest"], name: "index_api_keys_on_token_digest"
    t.index ["user_id"], name: "index_api_keys_on_user_id"
  end

  create_table "encounters", primary_key: "encounter_id", id: :string, force: :cascade do |t|
    t.string "patient_id", null: false
    t.string "provider_id", null: false
    t.datetime "encounter_date", precision: nil, null: false
    t.string "encounter_type", null: false
    t.json "clinical_data", default: {}
    t.string "created_by", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider_id"], name: "index_encounters_on_provider_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_users_on_name"
  end

  add_foreign_key "api_keys", "users"
end
