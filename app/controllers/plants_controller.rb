# app/controllers/plants_controller.rb
class PlantsController < ApplicationController
    def index
      if params[:query].present?
        @plants = Plant.where("CommonName ILIKE ? OR Genus ILIKE ? OR Species ILIKE ?", "%#{params[:query]}%", "%#{params[:query]}%", "%#{params[:query]}%")
      else
        @plants = Plant.all.limit(50)
      end
  
      respond_to do |format|
        format.html  # renders index.html.erb
        format.js    # used for AJAX search (if implemented)
      end
    end
  
    def show
      @plant = Plant.find(params[:id])
    end
  end
  