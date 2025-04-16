require 'faker'
require 'csv'
require 'securerandom'

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

puts "Seeded database with users, plant modules, sensors, time series data, care schedules, and unique plants!"
