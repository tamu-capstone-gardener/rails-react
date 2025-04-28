# Controller for managing sensor data display and notification settings
#
# @example Request to view a sensor's data
#   GET /sensors/123
#
# @example Request to update notification settings
#   PATCH /sensors/123/update_notification_settings
class SensorsController < ApplicationController
  # Displays sensor data with time series chart
  #
  # @param id [String] ID of the sensor to display
  # @param start_date [String] optional start date for time range
  # @param days [Integer] optional number of days to show (default: 10)
  # @return [void]
  def show
    @sensor = Sensor.find(params[:id])

    Time.use_zone(Time.zone.name) do
      if params[:start_date].present?
        start_time = Date.parse(params[:start_date])
      else
        days = params[:days].present? ? params[:days].to_i : 10
        start_time = days.days.ago
      end


      Rails.logger.info "Time zone is #{Time.zone.name}"
      @time_series_data = TimeSeriesDatum
                          .where(sensor_id: @sensor.id)
                          .where("timestamp >= ?", start_time)
                          .group_by_minute(:timestamp, time_zone: Time.zone.name)
                          .average(:value)
                          .transform_values do |v|
                            next nil if v.nil?
                            value = v.to_f
                            if @sensor.measurement_type == "light_analog"
                              ((4096 - value).abs / 4096.0 * 100).round(2)
                            else
                              value.round(2)
                            end
                          end
    end

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

  # Toggles notification settings for a sensor
  #
  # @param id [String] ID of the sensor to update
  # @return [void]
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

  # Updates notification thresholds and messages for a sensor
  #
  # @param id [String] ID of the sensor to update
  # @param comparisons [Array<String>] comparison operators for thresholds
  # @param values [Array<String>] threshold values
  # @param messages [Array<String>] notification messages
  # @param sensor [Hash] sensor parameters
  # @option sensor [String] :notifications whether notifications are enabled
  # @return [void]
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

  # Renders the notification settings form for a sensor
  #
  # @param id [String] ID of the sensor to load settings for
  # @return [void]
  def load_notification_settings
    @sensor = Sensor.find(params[:id])
    render partial: "sensors/notification_form", locals: { sensor: @sensor }
  end

  # Displays time series chart for a sensor with a specific time range
  #
  # @param id [String] ID of the sensor to display
  # @param range [String] time range to display ("1_day", "7_days", "30_days", "365_days")
  # @return [void]
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
                        .group_by_hour(:timestamp, time_zone: "Central Time (US & Canada)")
                        .average(:value)
                        .transform_values do |v|
                          next nil if v.nil?
                          value = v.to_f
                          if @sensor.measurement_type == "light_analog"
                            ((4096 - value).abs / 4096.0 * 100).round(2)
                          else
                            value.round(2)
                          end
                        end

    Rails.logger.info "Replacing the chart for #{@sensor.measurement_type}."
    render turbo_stream: turbo_stream.replace(
      "chart-#{params[:id]}",
      partial: "sensors/sensor_chart_inline",
      locals: { sensor: @sensor, data: hourly_data }
    )
  end
end
