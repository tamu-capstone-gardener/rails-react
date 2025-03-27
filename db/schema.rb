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

ActiveRecord::Schema[8.0].define(version: 2025_03_26_051553) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "care_schedules", id: :string, force: :cascade do |t|
    t.string "plant_module_id", null: false
    t.integer "watering_frequency"
    t.integer "fertilizer_frequency"
    t.integer "light_hours"
    t.string "soil_moisture_pref"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "module_plants", id: :string, force: :cascade do |t|
    t.string "plant_module_id", null: false
    t.string "plant_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["plant_module_id", "plant_id"], name: "index_unique_module_plants", unique: true
  end

  create_table "photos", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "timestamp", precision: nil, null: false
    t.string "plant_module_id", null: false
    t.string "url"
    t.index ["plant_module_id"], name: "index_photos_on_plant_module_id"
  end

  create_table "plant_modules", id: :string, force: :cascade do |t|
    t.string "user_id", null: false
    t.string "name", null: false
    t.text "description"
    t.string "location"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "location_type", default: "indoor", null: false
    t.string "zip_code"
  end

  create_table "plants", id: :string, force: :cascade do |t|
    t.string "family"
    t.string "genus"
    t.string "species"
    t.string "common_name"
    t.string "growth_rate"
    t.string "hardiness_zones"
    t.float "height"
    t.float "width"
    t.string "plant_type"
    t.string "leaf"
    t.string "flower"
    t.string "ripen"
    t.string "reproduction"
    t.text "soils"
    t.string "ph"
    t.text "preferences"
    t.text "tolerances"
    t.text "habitat"
    t.text "habitat_range"
    t.string "edibility"
    t.string "medicinal"
    t.text "other_uses"
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

  add_foreign_key "care_schedules", "plant_modules"
  add_foreign_key "module_plants", "plant_modules"
  add_foreign_key "module_plants", "plants"
  add_foreign_key "photos", "plant_modules"
  add_foreign_key "plant_modules", "users", primary_key: "uid"
  add_foreign_key "schedules", "plant_modules"
  add_foreign_key "sensors", "plant_modules"
  add_foreign_key "time_series_data", "sensors"
end
