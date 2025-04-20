FactoryBot.define do
  factory :sensor do
    id                  { SecureRandom.uuid }
    association :plant_module
    measurement_unit    { "units" }
    measurement_type    { "generic" }
    notifications       { false }
    messages            { [] }
    thresholds          { [] }
  end
end
