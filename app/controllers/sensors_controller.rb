class SensorsController < ApplicationController
  def show
    @sensor = Sensor.find(params[:id])
    @time_series_data = TimeSeriesDatum
                      .where(sensor_id: @sensor.id)
                      .group_by_day(:timestamp)
                      .sum(:value)
  end
end
