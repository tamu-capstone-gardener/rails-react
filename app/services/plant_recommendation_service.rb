class PlantRecommendationService
  include ZipCodeHelper
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

    Rails.logger.info("Trying to filter height: #{max_height} and width: #{max_width} and edibility: #{edibility_rating}")

    if max_height == 10.0 and max_width == 10.0 and edibility_rating == 3
      Plant
        .all
        .page(@filters[:page])
        .per(10)
    else
      Plant
        .where("height < ? AND width < ?", max_height, max_width)
        .where("CAST(edibility AS int) >= ?", edibility_rating)
        .page(@filters[:page])
        .per(10)
    end
  end


  def recommend_outdoor
    max_height = (@filters[:max_height].presence || 10.0).to_f
    max_width  = (@filters[:max_width].presence || 10.0).to_f
    edibility_rating = (@filters[:edibility_rating].presence || "3").to_i

    return Plant.all.page(@filters[:page]).per(10) if @zip_code == "" && max_height == 10.0 && max_width == 10.0 && edibility_rating == 3
    return Plant.where("height < ? AND width < ?", max_height, max_width)
                .where("CAST(edibility AS int) >= ?", edibility_rating)
                .page(@filters[:page]).per(10) if @zip_code == ""

    zone_data = zone_for_zip(@zip_code)
    return Plant.none unless zone_data

    zone_num = zone_data[:zone].match(/\d+/)[0]

    if max_height == 10.0 and max_width == 10.0 and edibility_rating == 3
      Plant.where("hardiness_zones ILIKE ?", "%#{zone_num}%")
           .page(@filters[:page])
           .per(10)
    else
      Plant.where("hardiness_zones ILIKE ?", "%#{zone_num}%")
           .where("height < ? AND width < ?", max_height, max_width)
           .where("CAST(edibility AS int) >= ?", edibility_rating)
           .page(@filters[:page])
           .per(10)
    end
  end
end
