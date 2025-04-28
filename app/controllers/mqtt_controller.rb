require "mqtt"

# Controller for sending MQTT messages to plant modules
#
# This controller handles sending control signals via MQTT protocol
# to the physical plant modules for actions like watering or changing
# light schedules.
class MqttController < AuthenticatedApplicationController
  before_action :set_secrets
  before_action :validate_set_schedule_params, only: [ :set_schedule ]
  before_action :validate_send_water_signal_params, only: [ :send_water_signal ]
  before_action :authorize_user, only: [ :set_schedule, :send_water_signal ]

  # Sets a watering schedule for a plant module
  #
  # @param plant_module_id [String] ID of the plant module to update
  # @param frequency [String] frequency of watering
  # @param units [String] time units for frequency (e.g., "hours", "days")
  # @return [void]
  def set_schedule
    message = { frequency: params[:frequency], units: params[:units] }.to_json
    publish_data(message, "#{@secrets[:topic]}/#{params[:plant_module_id]}/set_schedule")
    redirect_back fallback_location: plant_modules_path, notice: "Schedule set successfully"
  rescue => e
    redirect_back fallback_location: plant_modules_path, alert: "Error: #{e.message}"
  end

  # Sends a manual watering signal to a plant module
  #
  # @param plant_module_id [String] ID of the plant module to water
  # @return [void]
  def send_water_signal
    message = { water: true }.to_json
    publish_data(message, "#{@secrets[:topic]}/#{params[:plant_module_id]}/water")
    redirect_back fallback_location: plant_modules_path, notice: "Water signal sent successfully"
  rescue => e
    redirect_back fallback_location: plant_modules_path, alert: "Error: #{e.message}"
  end

  private

  # Sets MQTT broker credentials from Rails credentials
  #
  # @return [void]
  def set_secrets
    @secrets = Rails.application.credentials.hivemq
  end

  # Publishes a message to the MQTT broker
  #
  # @param message [String] JSON message to publish
  # @param topic [String] MQTT topic to publish to
  # @return [void]
  def publish_data(message, topic)
    MQTT::Client.connect(
      host: @secrets[:url],
      port: @secrets[:port],
    ) do |client|
      client.publish(topic, message)
    end
  end

  # Validates that required parameters for setting a schedule are present
  #
  # @return [void]
  def validate_set_schedule_params
    unless params[:frequency].present? && params[:units].present? && params[:plant_module_id].present?
      redirect_back fallback_location: plant_modules_path, alert: "Missing one or more of required parameters: frequency, units, and plant_module_id"
    end
  end

  # Validates that required parameters for sending a water signal are present
  #
  # @return [void]
  def validate_send_water_signal_params
    unless params[:plant_module_id].present?
      redirect_back fallback_location: plant_modules_path, alert: "Missing required parameter: plant_module_id"
    end
  end

  # Ensures the current user owns the plant module they're trying to control
  #
  # @return [void]
  def authorize_user
    plant_module = PlantModule.find_by(id: params[:plant_module_id])

    if plant_module.nil? || plant_module.user != current_user
      redirect_back fallback_location: plant_modules_path, alert: "You are not authorized to perform this action."
    end
  end
end
