# app/models/plant.rb
class Plant < ApplicationRecord
    def light_requirement
      # Use the instance attribute 'preferences' (lowercase), not the constant 'Preferences'
      if preferences.to_s.downcase.include?("shade") || preferences.to_s.downcase.include?("low light")
        "2-4"
      else
        "6-8"
      end
    end
end
