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

ActiveRecord::Schema[8.0].define(version: 2025021217533) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "plant_modules", id: :string, force: :cascade do |t|
    t.string "user_id", null: false
    t.string "name", null: false
    t.text "description"
    t.string "location"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "schedules", id: :string, force: :cascade do |t|
    t.string "plant_module_id", null: false
    t.integer "frequency"
    t.string "unit", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sensors", id: :string, force: :cascade do |t|
    t.string "plant_module_id", null: false
    t.string "measurement_unit"
    t.string "measurement_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "time_series_data", force: :cascade do |t|
    t.string "sensor_id", null: false
    t.datetime "timestamp", precision: nil, null: false
    t.float "value", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "full_name", null: false
    t.string "uid", null: false
    t.string "username", null: false
    t.string "provider", default: "google_oauth2", null: false
    t.string "avatar_url", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["uid"], name: "index_users_on_uid", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "plant_modules", "users", primary_key: "uid"
  add_foreign_key "schedules", "plant_modules"
  add_foreign_key "sensors", "plant_modules"
  add_foreign_key "time_series_data", "sensors"
end
