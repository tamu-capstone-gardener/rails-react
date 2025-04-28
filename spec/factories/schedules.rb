FactoryBot.define do
  factory :schedule do
    id                  { SecureRandom.uuid }
    association :plant_module
    frequency           { 1 }
    unit                { "days" }
  end
end
