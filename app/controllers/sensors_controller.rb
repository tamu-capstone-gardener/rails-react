class SensorsController < ApplicationController
  def show
    @sensor = Sensor.find(params[:id])
  
    if params[:start_date].present?
      start_time = Date.parse(params[:start_date])
    else
      days = params[:days].present? ? params[:days].to_i : 10
      start_time = days.days.ago
    end
  
    @time_series_data = TimeSeriesDatum
                        .where(sensor_id: @sensor.id)
                        .where("timestamp >= ?", start_time)
                        .group_by_minute(:timestamp)
                        .average(:value)
                        .transform_values { |v| v.to_f.round(2) }
  
    respond_to do |format|
      format.html
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "sensor_chart",
          partial: "sensors/chart",
          locals: { sensor: @sensor, time_series_data: @time_series_data }
        )
      end
    end
  end
end
