class CreateCareSchedules < ActiveRecord::Migration[8.0]
    def change
      create_table :care_schedules, id: :string do |t|
        t.string  :plant_module_id, null: false
        t.integer :watering_frequency   # in days
        t.integer :fertilizer_frequency # in days
        t.integer :light_hours          # recommended hours of light per day
        t.string  :soil_moisture_pref   # e.g., "Keep moderately moist" or "Allow to dry"

        t.timestamps
      end

      add_foreign_key :care_schedules, :plant_modules
    end
end
