# app/models/plant.rb

# @!attribute [r] id
#   @return [Integer] unique identifier for the plant
# @!attribute [rw] common_name
#   @return [String] common name of the plant
# @!attribute [rw] genus
#   @return [String] plant genus
# @!attribute [rw] species
#   @return [String] plant species
# @!attribute [rw] preferences
#   @return [String] plant light and other preferences
# @!attribute [rw] height
#   @return [Float] maximum height of the plant in feet
# @!attribute [rw] width
#   @return [Float] maximum width spread of the plant in feet
# @!attribute [rw] hardiness_zones
#   @return [String] USDA hardiness zones where the plant can grow
# @!attribute [rw] edibility
#   @return [String] edibility rating of the plant
class Plant < ApplicationRecord
  # Determines the light requirement range based on plant preferences
  #
  # @return [String] light requirement range in hours (e.g., "2-4" or "6-8")
  def light_requirement
    # Use the instance attribute 'preferences' (lowercase), not the constant 'Preferences'
    if preferences.to_s.downcase.include?("shade") || preferences.to_s.downcase.include?("low light")
      "2-4"
    else
      "6-8"
    end
  end
end
