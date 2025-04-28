# Controller for managing plant-related requests and views
#
# @example Request to list all plants
#   GET /plants
#
# @example Request to search plants
#   GET /plants?query=rose
class PlantsController < ApplicationController
  include ZipCodeHelper  # if you need to use helper methods here as well

  # Lists plants with optional filtering and pagination
  #
  # @note Plants can be filtered by query, location, dimensions, and more
  #
  # @param query [String] optional search term for plant name or species
  # @param location_type [String] "indoor" or "outdoor"
  # @param zip_code [String] optional ZIP code for outdoor plants
  # @param max_height [Float] maximum height filter
  # @param max_width [Float] maximum width filter
  # @param maintenance [String] maintenance level filter
  # @param edibility_rating [String] minimum edibility rating
  # @param page [Integer] pagination page number
  #
  # @return [void]
  def index
    if params[:query].present?
      @plants = Plant.where("common_name ILIKE ? OR genus ILIKE ? OR species ILIKE ?",
                            "%#{params[:query]}%", "%#{params[:query]}%", "%#{params[:query]}%")
                     .page(params[:page])
                     .per(5)
      Rails.logger.info "Found #{@plants.total_count} plants matching query '#{params[:query]}'"
    else
      filters = {
        max_height: params[:max_height],
        max_width: params[:max_width],
        maintenance: params[:maintenance],
        edibility_rating: params[:edibility_rating],
        page: params[:page]
      }

      if params[:location_type].to_s.downcase == "outdoor"
        service = PlantRecommendationService.new(location_type: "outdoor", zip_code: params[:zip_code], filters: filters)
      else
        service = PlantRecommendationService.new(location_type: "indoor", filters: filters)
      end

      @plants = service.recommendations
    end

    if turbo_frame_request?
      render partial: "plants/recommendations_frame", locals: { plants: @plants }
    else
      render :index
    end
  end

  # Displays detailed information for a specific plant
  #
  # @param id [Integer] ID of the plant to show
  #
  # @return [void]
  def info
    @plant = Plant.find(params[:id])
    render partial: "plants/info", locals: { plant: @plant }
  end
end
