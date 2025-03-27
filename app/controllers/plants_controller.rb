class PlantsController < ApplicationController
  def index
    if params[:query].present?
      @plants = Plant.where("common_name ILIKE ? OR genus ILIKE ? OR species ILIKE ?",
                            "%#{params[:query]}%", "%#{params[:query]}%", "%#{params[:query]}%")
    else
      filters = {
        max_height: params[:max_height],
        max_width: params[:max_width],
        maintenance: params[:maintenance],
        edible: params[:edible]
      }
      # Here we assume indoor recommendations; adjust if you pass a location_type via params.
      @plants = PlantRecommendationService.new(location_type: "indoor", filters: filters).recommendations
    end

    if turbo_frame_request?
      render partial: "plants/recommendations", locals: { plants: @plants }
    else
      render :index
    end
  end
end
