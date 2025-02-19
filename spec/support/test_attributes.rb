module TestAttributes
  module User
    def self.valid
      {
        email: "user@example.com",
        full_name: "John Doe",
        uid: "1234567890",
        username: "johndoe",
        provider: "google_oauth2",
        avatar_url: "https://example.com/avatar.png"
      }
    end

    def self.other_user
      {
        email: "other_user@example.com",
        full_name: "Jane Smith",
        uid: "0987654321",
        username: "janesmith",
        provider: "google_oauth2",
        avatar_url: "https://example.com/other_avatar.png"
      }
    end
  end

  module PlantModule
    def self.valid
      {
        id: "pm_123",
        user_id: "user_456",
        name: "Tomato Hydroponics",
        description: "A hydroponic module for growing tomatoes",
        location: "Greenhouse A"
      }
    end
  end

  module Sensor
    def self.valid
      {
        id: "sensor_789",
        plant_module_id: "pm_123",
        measurement_unit: "Celsius",
        measurement_type: "Temperature"
      }
    end
  end
end
