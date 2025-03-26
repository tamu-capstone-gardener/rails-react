class PlantsController < ApplicationController
  include ZipCodeHelper  # if you need to use helper methods here as well

  def index
    Rails.logger.error "INDEX ACTION HIT"
    
    if params[:query].present?
      @plants = Plant.where("common_name ILIKE ? OR genus ILIKE ? OR species ILIKE ?", 
                            "%#{params[:query]}%", "%#{params[:query]}%", "%#{params[:query]}%")
      Rails.logger.error "Found #{@plants.count} plants matching query '#{params[:query]}'"
    else
      filters = {
        max_height: params[:max_height],
        max_width: params[:max_width],
        maintenance: params[:maintenance],
        edibility_rating: params[:edibility_rating]
      }
      
      # Decide on indoor vs. outdoor based on a parameter.
      # For example, if params[:location_type] is "outdoor", pass zip_code and "outdoor".
      if params[:location_type].to_s.downcase == "outdoor"
        service = PlantRecommendationService.new(location_type: "outdoor", zip_code: params[:zip_code], filters: filters)
      else
        service = PlantRecommendationService.new(location_type: "indoor", filters: filters)
      end
      
      @plants = service.recommendations
    end

    if turbo_frame_request?
      render turbo_stream: turbo_stream.replace("recommendations",
        partial: "plants/recommendations",
        locals: { plants: @plants }
      )
    else
      render :index
    end
  end
end
