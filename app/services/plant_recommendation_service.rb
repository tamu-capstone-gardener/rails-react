# app/services/plant_recommendation_service.rb
class PlantRecommendationService
    def initialize(location_type:, zip_code: nil)
      @location_type = location_type
      @zip_code = zip_code
    end
  
    def recommendations
      if indoor?
        recommend_indoor
      else
        recommend_outdoor
      end
    end
  
    private
  
    def indoor?
      @location_type.downcase == "indoor"
    end
  
    def recommend_indoor
      # For demonstration, we filter by plants small enough to fit inside a 17-gal box
      # and that have "indoor" mentioned in Preferences.
      Plant.where("height < ? AND width < ?", 1.0, 1.0)
           .where("preferences ILIKE ?", "%indoor%")
           .limit(5)
           .to_a
    end
  
    def recommend_outdoor
      zone = lookup_zone(@zip_code)
      # Filter plants whose HardinessZones include the given zone (simple string match)
      Plant.where("hardiness_zones ILIKE ?", "%#{zone}%")
           .limit(5)
           .to_a
    end
  
    def lookup_zone(zip)
      # Here you would implement a lookup using your phzm_us_zipcode_2023.csv data.
      # For demonstration purposes, we return a hardcoded value.
      "7b"
    end
  end
  