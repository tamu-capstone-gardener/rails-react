FactoryBot.define do
  factory :plant do
    id                  { SecureRandom.uuid }
    family              { "Rosaceae" }
    genus               { "Rosa" }
    species             { "Rosa rubiginosa" }
    common_name         { "Sweet Briar" }
    growth_rate         { "moderate" }
    hardiness_zones     { "5-9" }
    height              { 1.2 }
    width               { 0.8 }
    plant_type          { "shrub" }
    leaf                { "compound" }
    flower              { "pink" }
    ripen               { "summer" }
    reproduction        { "seeds" }
    soils               { "Loamy" }
    ph                  { "6.0-7.0" }
    preferences         { "Full sun" }
    tolerances          { "Drought" }
    habitat             { "Woodlands" }
    habitat_range       { "Europe" }
    edibility           { "non-edible" }
    medicinal           { "none" }
    other_uses          { "ornamental" }
    foliage             { "evergreen" }
    ph_split            { nil }
    pollinators         { "bees" }
    pfaf                { nil }
  end
end
