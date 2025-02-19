class PlantModulesController < ApplicationController
  def show
    @plant_module = PlantModule.find(params[:id])
    @sensors = @plant_module.sensors.includes(:time_series_data)
  end
end
