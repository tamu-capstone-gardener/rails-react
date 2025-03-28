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

    edibility_rating = (@filters[:edibility_rating].presence || "3").to_i

    Plant
      .where("height < ? AND width < ?", max_height, max_width)
      .where("CAST(edibility AS int) >= ?", edibility_rating)
      .page(@filters[:page])
      .per(5)
  end


  def recommend_outdoor
    return Plant.none if @zip_code.blank?

    zone_data = zone_for_zip(@zip_code)
    return Plant.none unless zone_data

    zone_num = zone_data[:zone].match(/\d+/)[0]

    max_height = (@filters[:max_height].presence || 10.0).to_f
    max_width  = (@filters[:max_width].presence || 10.0).to_f
    edibility_rating = (@filters[:edibility_rating].presence || "3").to_i

    Plant
      .where("hardiness_zones ILIKE ?", "%#{zone_num}%")
      .where("height < ? AND width < ?", max_height, max_width)
      .where("CAST(edibility AS int) >= ?", edibility_rating)
      .page(@filters[:page])
      .per(5)
  end
end
