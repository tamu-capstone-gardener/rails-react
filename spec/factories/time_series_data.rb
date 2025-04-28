FactoryBot.define do
  factory :time_series_datum do
    association :sensor
    timestamp           { Time.current }
    value               { rand * 100 }
    notified_threshold_indices { [] }
  end
end
