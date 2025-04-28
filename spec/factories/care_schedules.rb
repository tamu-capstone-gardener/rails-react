FactoryBot.define do
  factory :care_schedule do
    id                   { SecureRandom.uuid }
    association          :plant_module
    watering_frequency   { 7 }
    fertilizer_frequency { 14 }
    light_hours          { 12 }
    soil_moisture_pref   { "moderate" }
  end
end
