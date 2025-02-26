class PlantModulesController < ApplicationController
  def show
    @plant_module = PlantModule.find(params[:id])
    @sensors = @plant_module.sensors.includes(:time_series_data)

    @sensor_data = {}
    @sensors.each do |sensor|
      @sensor_data[sensor.id] = sensor.time_series_data
                                      .group("DATE(timestamp)")
                                      .pluck(Arel.sql("DATE(timestamp), SUM(value)"))
    end
  end

  def index
    @plant_modules = PlantModule.all
  end
end
