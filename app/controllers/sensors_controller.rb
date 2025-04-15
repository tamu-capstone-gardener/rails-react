class SensorsController < ApplicationController
  before_action :set_plant_module, only: [ :new, :create ]

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
                        .transform_values { |v| v.nil? ? nil : v.to_f.round(2) }

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

  def new
    @sensor = @plant_module.sensors.new
  end

  def create
    @sensor = @plant_module.sensors.new(sensor_params)
    if @sensor.save
      respond_to do |format|
        format.turbo_stream do
          @sensors = @plant_module.sensors
          @sensor_data = {}
          @sensors.each do |sensor|
            @sensor_data[sensor.id] = sensor.time_series_data.group("DATE(timestamp)").pluck(Arel.sql("DATE(timestamp), SUM(value)"))
          end
          render turbo_stream: turbo_stream.replace(
            "sensors_list",
            partial: "sensors/list",
            locals: { plant_module: @plant_module, sensors: @sensors, sensor_data: @sensor_data }
          )
        end
        format.html { redirect_to plant_module_path(@plant_module), notice: "Sensor added successfully." }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def toggle_notification
    @sensor = Sensor.find(params[:id])
    @sensor.update(notifications: !@sensor.notifications)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "notification_section",
          partial: "sensors/notification_section",
          locals: { sensor: @sensor }
        )
      end
      format.html { redirect_to plant_module_sensor_path(@sensor.plant_module, @sensor) }
    end
  end



  def update_notification_settings
    @sensor = Sensor.find(params[:id])
    comparisons = params[:comparisons] || []
    values = params[:values] || []
    messages = params[:messages] || []
    thresholds = comparisons.zip(values).map { |comp, val| "#{comp} #{val}" }
    notifications = params[:sensor][:notifications] == "1"

    if @sensor.update(thresholds: thresholds, messages: messages, notifications: notifications)
      flash.now[:notice] = "Notification settings updated."
    else
      flash.now[:alert] = "Unable to update settings."
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "notification_section",
          partial: "sensors/notification_section",
          locals: { sensor: @sensor }
        )
      end
      format.html { redirect_to plant_module_sensor_path(@sensor.plant_module, @sensor) }
    end
  end


  def load_notification_settings
    @sensor = Sensor.find(params[:id])
    render partial: "sensors/notification_form", locals: { sensor: @sensor }
  end

  def time_series_chart
    @sensor = Sensor.find(params[:id])
    range = params[:range] || "30_days"

    time_ago = case range
    when "1_day" then 1.day.ago
    when "7_days" then 7.days.ago
    when "30_days" then 30.days.ago
    when "365_days" then 1.year.ago
    else 30.days.ago
    end

    hourly_data = @sensor.time_series_data
                        .where("timestamp >= ?", time_ago)
                        .group_by_hour(:timestamp)
                        .average(:value)
                        .transform_values { |v| v&.to_f&.round(2) }

    render turbo_stream: turbo_stream.replace(
      "chart-#{params[:id]}",
      partial: "sensors/sensor_chart_inline",
      locals: { sensor: @sensor, data: hourly_data }
    )
  end




  private

  def set_plant_module
    @plant_module = PlantModule.find(params[:plant_module_id])
  end

  def sensor_params
    params.require(:sensor).permit(:measurement_type, :measurement_unit)
  end
end
