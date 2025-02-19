require 'faker'

User.destroy_all
PlantModule.destroy_all
Sensor.destroy_all
TimeSeriesDatum.destroy_all
Schedule.destroy_all

# Create users
5.times do
  user = User.create!(
    email: Faker::Internet.unique.email,
    full_name: Faker::Name.name,
    uid: SecureRandom.uuid,
    username: Faker::Internet.unique.username,
    avatar_url: Faker::Avatar.image
  )

  # Create plant modules for each user
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

      # Generate time series data for each sensor
      10.times do
        sensor.time_series_data.create!(
          timestamp: Faker::Time.backward(days: 5, period: :all),
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
