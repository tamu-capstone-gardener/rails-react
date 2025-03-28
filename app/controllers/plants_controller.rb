class PlantsController < ApplicationController
  include ZipCodeHelper  # if you need to use helper methods here as well

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
end
