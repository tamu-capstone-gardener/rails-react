class PlantRecommendationService
  def initialize(location_type:, zip_code: nil, filters: {})
    @location_type = location_type
    @zip_code = zip_code
    @filters = filters
  end

  def recommendations
    indoor? ? recommend_indoor : recommend_outdoor
  end

  private

  def indoor?
    @location_type.downcase == "indoor"
  end

  def recommend_indoor
    # Use filter values if provided; defaults below
    max_height = (@filters[:max_height].presence || 10.0).to_f
    max_width  = (@filters[:max_width].presence || 10.0).to_f
    maintenance = (@filters[:maintenance].presence || "slow").downcase
    edible = (@filters[:edible].presence || "yes").downcase

    query = Plant.where("height < ? AND width < ?", max_height, max_width)

    # Apply edible filter: if "yes", require rating >= 3; if "no", rating < 3; if "either", do nothing.
    case edible
    when "yes"
      query = query.where("CAST(substring(edibility from '\\((\\d+)') AS int) >= ?", 4)
    when "no"
      query = query.where("CAST(substring(edibility from '\\((\\d+)') AS int) < ?", 3)
    end

    # Apply maintenance filter: check growth_rate or preferences contain the given keyword.
    query = query.where("(growth_rate ILIKE ? OR preferences ILIKE ?)", "%#{maintenance}%", "%#{maintenance}%")

    query.limit(15).to_a
  end

  def recommend_outdoor
    zone = lookup_zone(@zip_code)
    Plant.where("hardiness_zones ILIKE ?", "%#{zone}%")
         .limit(15)
         .to_a
  end

  def lookup_zone(zip)
    # Replace with your real lookup logic.
    "9b"
  end
end
