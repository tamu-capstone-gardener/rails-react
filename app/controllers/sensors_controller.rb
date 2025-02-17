class SensorsController < ApplicationController
    def show
      @sensor = Sensor.find(params[:id])
      @time_series_data = @sensor.time_series_data.order(timestamp: :asc)
    end
  end
  