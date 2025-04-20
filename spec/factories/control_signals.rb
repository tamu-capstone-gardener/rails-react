FactoryBot.define do
  factory :control_signal do
    id            { SecureRandom.uuid }
    association   :plant_module
    signal_type   { "pump" }
    label         { "Test Pump" }
    mqtt_topic    { "#{plant_module.id}/pump" }
    delay         { 3000 }
    mode          { "manual" }
    sensor_id     { nil }
    comparison    { nil }
    threshold_value { nil }
    frequency     { nil }
    unit          { nil }
    enabled       { true }
    length        { 3000 }
    length_unit   { "seconds" }
    scheduled_time { nil }
  end
end
