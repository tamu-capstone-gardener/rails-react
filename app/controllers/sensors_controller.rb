class SensorsController < ApplicationController
  def show
    @sensor = Sensor.find(params[:id])
    days = params[:days].present? ? params[:days].to_i : 10

    @time_series_data = TimeSeriesDatum
                        .where(sensor_id: @sensor.id)
                        .where("timestamp >= ?", days.days.ago)
                        .group_by_day(:timestamp)
                        .sum(:value)

    respond_to do |format|
      format.html
      format.turbo_stream { render turbo_stream: turbo_stream.replace("sensor_chart", partial: "sensors/chart", locals: { sensor: @sensor, time_series_data: @time_series_data }) }
    end
  end
end
