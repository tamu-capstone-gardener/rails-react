# app/models/care_schedule.rb
class CareSchedule < ApplicationRecord
    belongs_to :plant_module

  # Attributes might include:
  # watering_frequency (integer, in days), fertilizer_frequency (integer, in days),
  # light_hours (integer), soil_moisture_pref (string)
end
