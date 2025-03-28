require 'faker'
require 'csv'
require 'securerandom'

# -------------------------------
# 1. Clean-up Existing Data
# -------------------------------
# Preserve only Gmail users and delete the rest
User.where.not("email LIKE ? OR email LIKE ?", "%@gmail.com", "%@tamu.edu").destroy_all

# Clean up other related records
PlantModule.destroy_all
Sensor.destroy_all
TimeSeriesDatum.destroy_all
Schedule.destroy_all
# Also clear care_schedules and module_plants if needed
CareSchedule.destroy_all
ModulePlant.destroy_all

# -------------------------------
# 2. Create or Collect Users
# -------------------------------
existing_users = User.where("email LIKE ?", "%@gmail.com").to_a
users_needed = 5 - existing_users.count

users_needed.times do
  existing_users << User.create!(
    email: Faker::Internet.unique.email,
    full_name: Faker::Name.name,
    uid: SecureRandom.uuid,
    username: Faker::Internet.unique.username,
    avatar_url: Faker::Avatar.image
  )
end

# -------------------------------
# 3. Create Plant Modules for Each User
# -------------------------------
existing_users.each do |user|
  2.times do
    # Create a new PlantModule. (Note: You might want to set location_type explicitly.)
    plant_module = user.plant_modules.create!(
      id: SecureRandom.uuid,
      name: Faker::Lorem.word.capitalize,
      description: Faker::Lorem.sentence,
      location: Faker::Address.city,
      location_type: [ 'indoor', 'outdoor' ].sample,  # Randomly assign indoor/outdoor for demo
      zip_code: (rand(10000..99999)).to_s             # Only used for outdoor modules
    )

    # Ensure the module gets at least one plant.
    if Plant.exists?
      # You can choose the first plant or a random one.
      chosen_plant = Plant.order("RANDOM()").first
      plant_module.module_plants.create!(
        id: SecureRandom.uuid,
        plant_id: chosen_plant.id
      )
    end

    # Create sensors for each plant module
    3.times do
      sensor = plant_module.sensors.create!(
        id: SecureRandom.uuid,
        measurement_unit: [ 'Celsius', 'Lux', 'Moisture' ].sample,
        measurement_type: [ 'Temperature', 'Light', 'Soil Moisture' ].sample
      )

      # Generate up to 100 days of time series data
      100.times do |i|
        sensor.time_series_data.create!(
          timestamp: i.days.ago + rand(0..86400), # Random time within each day
          value: rand(10.0..100.0)
        )
      end
    end

    # -------------------------------
    # 4. Create a Default Care Schedule for the Plant Module
    # -------------------------------
    # For simplicity, we'll set the care schedule based on the location_type.
    default_schedule =
      if plant_module.location_type.downcase == "indoor"
        {
          watering_frequency: 7,
          fertilizer_frequency: 30,
          light_hours: 6,
          soil_moisture_pref: "Keep moderately moist"
        }
      else
        {
          watering_frequency: 7,
          fertilizer_frequency: 30,
          light_hours: 8,
          soil_moisture_pref: "Ensure well-draining soil; water deeply once a week"
        }
      end

    # Create a single care_schedule record for this module.
    plant_module.create_care_schedule!(default_schedule.merge("id" => SecureRandom.uuid))
  end
end

# -------------------------------
# 5. Import Plants from CSV (Deduplicated)
# -------------------------------
COLUMN_MAPPING = {
  "Family"         => "family",
  "Genus"          => "genus",
  "Species"        => "species",
  "CommonName"     => "common_name",
  "GrowthRate"     => "growth_rate",
  "HardinessZones" => "hardiness_zones",
  "Height"         => "height",
  "Width"          => "width",
  "Type"           => "plant_type",  # Using plant_type instead of 'type'
  "Foliage"        => "foliage",
  "Pollinators"    => "pollinators",
  "Leaf"           => "leaf",
  "Flower"         => "flower",
  "Ripen"          => "ripen",
  "Reproduction"   => "reproduction",
  "Soils"          => "soils",
  "pH"             => "ph",
  "pH_split"       => "ph_split",
  "Preferences"    => "preferences",
  "Tolerances"     => "tolerances",
  "Habitat"        => "habitat",
  "HabitatRange"   => "habitat_range",
  "Edibility"      => "edibility",
  "Medicinal"      => "medicinal",
  "OtherUses"      => "other_uses",
  "PFAF"           => "pfaf"
}

csv_file_path = Rails.root.join('app/assets/csv/pfaf_plants.csv')

CSV.foreach(csv_file_path, headers: true) do |row|
  plant_attributes = row.to_hash.transform_keys do |key|
    COLUMN_MAPPING[key] || key.downcase
  end

  genus = plant_attributes['genus']&.strip&.downcase
  species = plant_attributes['species']&.strip&.downcase
  common_name = plant_attributes['common_name']&.strip&.downcase

  next if genus.present? && species.present? &&
    Plant.where('LOWER(genus) = ? AND LOWER(species) = ?', genus, species).exists?

  next if (genus.blank? || species.blank?) && common_name.present? &&
    Plant.where('LOWER(common_name) = ?', common_name).exists?

  # Merge in a generated UUID for the id.
  Plant.create!(plant_attributes.merge("id" => SecureRandom.uuid))
end

puts "✅ Seeded database with users, plant modules, sensors, time series data, care schedules, and unique plants!"
