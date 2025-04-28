FactoryBot.define do
  factory :sensor_notification_log do
    sensor { nil }
    threshold_index { 1 }
    last_sent_at { "2025-04-24 19:43:23" }
  end
end
