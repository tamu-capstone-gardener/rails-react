FactoryBot.define do
  factory :plant_module do
    id                  { SecureRandom.uuid }
    association :user
    name                { "Test Module" }
    description         { "A test plant module" }
    location            { "Lab" }
    location_type       { "indoor" }
    zip_code            { "12345" }
    hardware_config     { {} }
  end
end
