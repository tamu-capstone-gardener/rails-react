# app/services/care_schedule_calculator.rb

# Service for calculating optimal care schedules based on plant requirements
#
# This service analyzes a collection of plants and determines the optimal
# watering, fertilizing, and light schedules to meet the needs of all plants
# in a plant module.
class CareScheduleCalculator
    # Initializes a new care schedule calculator
    #
    # @param plants [Array<Plant>, ActiveRecord::Relation] plants to calculate schedule for
    # @return [CareScheduleCalculator] a new instance ready to calculate a care schedule
    def initialize(plants)
      @plants = plants
    end

    # Calculates the recommended care schedule
    #
    # @return [Hash] recommended care schedule with watering, fertilizer, light, and soil moisture preferences
    # @option return [Integer] :watering_frequency days between watering
    # @option return [Integer] :fertilizer_frequency days between fertilizing
    # @option return [Integer] :light_hours recommended hours of light per day
    # @option return [String] :soil_moisture_pref recommended soil moisture level
    def calculate
      if @plants.any?
        {
          watering_frequency: recommended_watering_frequency,
          fertilizer_frequency: recommended_fertilizer_frequency,
          light_hours: recommended_light_hours,
          soil_moisture_pref: recommended_soil_moisture_pref
        }
      else
        # Fallback defaults if no plants are associated
        {
          watering_frequency: 7,
          fertilizer_frequency: 30,
          light_hours: 8,
          soil_moisture_pref: "medium"
        }
      end
    end

    private

    # Calculates the recommended watering frequency
    #
    # @note Fast growing plants require more frequent watering
    # @return [Integer] days between watering
    def recommended_watering_frequency
      frequencies = @plants.map do |plant|
        case plant.growth_rate.to_s.downcase
        when "fast" then 2
        when "moderate" then 4
        when "slow" then 7
        else 7
        end
      end
      frequencies.min
    end

    # Calculates the recommended fertilizer frequency
    #
    # @note Slow growing plants require less frequent fertilizing
    # @return [Integer] days between fertilizing
    def recommended_fertilizer_frequency
      frequencies = @plants.map do |plant|
        case plant.growth_rate.to_s.downcase
        when "fast" then 14
        when "moderate" then 30
        when "slow" then 45
        else 30
        end
      end
      frequencies.max
    end

    # Calculates the recommended light hours per day
    #
    # @return [Integer] hours of light per day
    def recommended_light_hours
      hours = @plants.map do |plant|
        # For example, deciduous plants might require around 8 hours,
        # while others might do with a bit less.
        plant.plant_type.to_s.downcase == "deciduous" ? 8 : 6
      end
      (hours.sum / hours.size.to_f).round
    end

    # Determines the recommended soil moisture preference
    #
    # @return [String] soil moisture preference ("low", "medium", or "high")
    def recommended_soil_moisture_pref
      prefs = @plants.map do |plant|
        soils = parse_soils(plant.soils)
        # As an example, pick the first soil type in the array (or adjust as needed)
        soils.first || "medium"
      end
      # Choose the most common preference among the plants.
      prefs.group_by(&:itself).max_by { |_k, v| v.size }&.first || "medium"
    end

    # Parses soil preference string into an array
    #
    # @param soils_string [String] JSON string of soil preferences
    # @return [Array<String>] parsed soil preferences
    def parse_soils(soils_string)
      return [] unless soils_string.present?
      begin
        result = JSON.parse(soils_string)
        result.is_a?(Array) ? result : []
      rescue JSON::ParserError
        []
      end
    end
end
