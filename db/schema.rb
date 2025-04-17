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

ActiveRecord::Schema[8.0].define(version: 2025_04_17_042937) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "care_schedules", id: :string, force: :cascade do |t|
    t.string "plant_module_id", null: false
    t.integer "watering_frequency"
    t.integer "fertilizer_frequency"
    t.integer "light_hours"
    t.string "soil_moisture_pref"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "control_executions", id: :string, force: :cascade do |t|
    t.string "control_signal_id", null: false
    t.string "source", null: false
    t.integer "duration", null: false
    t.datetime "executed_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "status", default: false, null: false
    t.string "duration_unit", default: "seconds", null: false
    t.index ["control_signal_id"], name: "index_control_executions_on_control_signal_id"
  end

  create_table "control_signals", id: :string, force: :cascade do |t|
    t.string "plant_module_id", null: false
    t.string "signal_type", null: false
    t.string "label"
    t.string "mqtt_topic"
    t.integer "delay", default: 3000
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "mode", default: "manual", null: false
    t.string "sensor_id"
    t.string "comparison"
    t.float "threshold_value"
    t.integer "frequency"
    t.string "unit"
    t.boolean "enabled", default: true
    t.integer "length", default: 3000
    t.time "scheduled_time"
    t.string "length_unit", default: "seconds", null: false
    t.index ["plant_module_id", "signal_type"], name: "index_control_signals_on_plant_module_id_and_signal_type"
    t.index ["sensor_id"], name: "index_control_signals_on_sensor_id"
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
    t.jsonb "hardware_config", default: {}
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
    t.string "foliage"
    t.string "ph_split"
    t.string "pollinators"
    t.string "pfaf"
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
    t.boolean "notifications", default: false, null: false
    t.string "messages", default: [], array: true
    t.string "thresholds", default: [], array: true
  end

  create_table "time_series_data", force: :cascade do |t|
    t.string "sensor_id", null: false
    t.datetime "timestamp", precision: nil, null: false
    t.float "value", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "notified_threshold_indices"
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
    t.string "zip_code"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["uid"], name: "index_users_on_uid", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "care_schedules", "plant_modules"
  add_foreign_key "control_executions", "control_signals"
  add_foreign_key "control_signals", "plant_modules"
  add_foreign_key "control_signals", "sensors"
  add_foreign_key "module_plants", "plant_modules"
  add_foreign_key "module_plants", "plants"
  add_foreign_key "photos", "plant_modules"
  add_foreign_key "plant_modules", "users", primary_key: "uid"
  add_foreign_key "schedules", "plant_modules"
  add_foreign_key "sensors", "plant_modules"
  add_foreign_key "time_series_data", "sensors"
end
