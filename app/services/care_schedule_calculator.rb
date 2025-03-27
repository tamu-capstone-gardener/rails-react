# app/services/care_schedule_calculator.rb
class CareScheduleCalculator
    def initialize(plants)
      @plants = plants
    end
  
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
  
    # Example: a "fast" growing plant may require more frequent watering.
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
  
    # Example: fertilize less frequently for slow growers.
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
  
    # Here we assume a default light requirement based on plant type.
    def recommended_light_hours
      hours = @plants.map do |plant|
        # For example, deciduous plants might require around 8 hours,
        # while others might do with a bit less.
        plant.plant_type.to_s.downcase == "deciduous" ? 8 : 6
      end
      (hours.sum / hours.size.to_f).round
    end
  
    # For soil moisture preference, we can attempt to parse the stored soils array and choose the most common.
    def recommended_soil_moisture_pref
      prefs = @plants.map do |plant|
        soils = parse_soils(plant.soils)
        # As an example, pick the first soil type in the array (or adjust as needed)
        soils.first || "medium"
      end
      # Choose the most common preference among the plants.
      prefs.group_by(&:itself).max_by { |_k, v| v.size }&.first || "medium"
    end
  
    # Attempt to convert the stored string into an array.
    def parse_soils(soils_string)
      return [] unless soils_string.present?
      begin
        result = eval(soils_string)  # Use with caution—ensure your data is trusted!
        result.is_a?(Array) ? result : []
      rescue StandardError
        []
      end
    end
  end
  