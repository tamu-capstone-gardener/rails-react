FactoryBot.define do
  factory :user do
    sequence(:email)   { |n| "user#{n}@example.com" }
    full_name          { "Test User" }
    uid                { SecureRandom.uuid }
    sequence(:username) { |n| "testuser#{n}" }
    provider           { "google_oauth2" }
    avatar_url         { "http://example.com/avatar.png" }
    zip_code           { "12345" }
  end
end
