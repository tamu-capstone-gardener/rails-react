class PlantRecommendationService
  include ZipCodeHelper  # This makes zone_for_zip available

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
    max_height = (@filters[:max_height].presence || 10.0).to_f
    max_width  = (@filters[:max_width].presence || 10.0).to_f

    query = Plant.where("height < ? AND width < ?", max_height, max_width)

    edibility_rating = (@filters[:edibility_rating].presence || "3").to_i
    query = query.where("CAST(substring(edibility from '\\((\\d+)') AS int) >= ?", edibility_rating)

    query.limit(15).to_a
  end

  def recommend_outdoor
    return [] if @zip_code.blank?
    zone_data = zone_for_zip(@zip_code)
    return [] unless zone_data

    zone_str = zone_data[:zone]       # e.g., "9b"
    zone_num = zone_str.match(/\d+/)[0] # extracts "9"
    Rails.logger.info "Using zone number: #{zone_num} for outdoor recommendations"

    max_height = (@filters[:max_height].presence || 10.0).to_f
    max_width  = (@filters[:max_width].presence || 10.0).to_f

    query = Plant.where("hardiness_zones ILIKE ?", "%#{zone_num}%")

    query = query.where("height < ? AND width < ?", max_height, max_width)

    edibility_rating = (@filters[:edibility_rating].presence || "3").to_i
    query = query.where("CAST(substring(edibility from '\\((\\d+)') AS int) >= ?", edibility_rating)

    query.limit(15).to_a
  end
  
end
