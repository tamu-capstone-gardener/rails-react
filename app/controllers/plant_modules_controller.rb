class PlantModulesController < ApplicationController
  def show
    @plant_module = PlantModule.find(params[:id])
  end
end
