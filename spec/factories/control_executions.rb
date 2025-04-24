# spec/factories/control_executions.rb
FactoryBot.define do
  factory :control_execution do
    id              { SecureRandom.uuid }
    association     :control_signal
    source          { "scheduled" }
    duration        { 1000 }
    duration_unit   { "seconds" }
    executed_at     { Time.current }
    status          { true }
  end
end
