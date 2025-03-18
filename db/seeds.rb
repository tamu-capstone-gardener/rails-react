require 'faker'

# Preserve users with @gmail.com emails, delete the rest
User.where.not("email LIKE ?", "%@gmail.com").destroy_all

PlantModule.destroy_all
Sensor.destroy_all
TimeSeriesDatum.destroy_all
Schedule.destroy_all

# Retrieve existing Gmail users and add new ones if needed
existing_users = User.where("email LIKE ?", "%@gmail.com").to_a
users_needed = 5 - existing_users.count

users_needed.times do
  existing_users << User.create!(
    email: Faker::Internet.unique.email,
    full_name: Faker::Name.name,
    uid: SecureRandom.uuid,
    username: Faker::Internet.unique.username,
    avatar_url: Faker::Avatar.image
  )
end

# Ensure every user (including existing Gmail users) has plant modules, sensors, and schedules
existing_users.each do |user|
  2.times do
    plant_module = user.plant_modules.create!(
      id: SecureRandom.uuid,
      name: Faker::Lorem.word.capitalize,
      description: Faker::Lorem.sentence,
      location: Faker::Address.city
    )

    # Create sensors for each plant module
    3.times do
      sensor = plant_module.sensors.create!(
        id: SecureRandom.uuid,
        measurement_unit: [ 'Celsius', 'Lux', 'Moisture' ].sample,
        measurement_type: [ 'Temperature', 'Light', 'Soil Moisture' ].sample
      )

      # Generate up to 100 days of time series data
      100.times do |i|
        sensor.time_series_data.create!(
          timestamp: i.days.ago + rand(0..86400), # Random time within each day
          value: rand(10.0..100.0)
        )
      end
    end

    # Create schedules for each plant module
    2.times do
      plant_module.schedules.create!(
        id: SecureRandom.uuid,
        frequency: [ 1, 2, 4, 8, 12, 24 ].sample,
        unit: [ 'minutes', 'hours', 'days', 'weeks' ].sample
      )
    end
  end
end

puts "✅ Seeded database with users, plant modules, sensors, and time series data!"
