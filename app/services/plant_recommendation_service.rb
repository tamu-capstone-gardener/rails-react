# Service for providing personalized plant recommendations
#
# This service filters plants based on location type (indoor/outdoor),
# geographic location (for outdoor plants), and user preferences such as
# size constraints and edibility requirements.
class PlantRecommendationService
  include ZipCodeHelper

  # Initializes a new recommendation service
  #
  # @param location_type [String] "indoor" or "outdoor"
  # @param zip_code [String, nil] ZIP code for outdoor plants to determine hardiness zone
  # @param filters [Hash] additional filtering criteria
  # @option filters [String, Float] :max_height Maximum height in feet
  # @option filters [String, Float] :max_width Maximum width in feet
  # @option filters [String, Integer] :edibility_rating Minimum edibility rating (1-5)
  # @option filters [Integer] :page Pagination page number
  def initialize(location_type:, zip_code: nil, filters: {})
    @location_type = location_type
    @zip_code = zip_code
    @filters = filters
  end

  # Provides plant recommendations based on location type and filters
  #
  # @return [ActiveRecord::Relation] paginated collection of recommended plants
  def recommendations
    indoor? ? recommend_indoor : recommend_outdoor
  end

  private

  # Determines if the location type is indoor
  #
  # @return [Boolean] true if indoor, false if outdoor
  def indoor?
    @location_type.downcase == "indoor"
  end

  # Recommends plants suitable for indoor environments
  #
  # @return [ActiveRecord::Relation] paginated collection of indoor plants
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

  # Recommends plants suitable for outdoor environments based on hardiness zone
  #
  # @return [ActiveRecord::Relation] paginated collection of outdoor plants
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
