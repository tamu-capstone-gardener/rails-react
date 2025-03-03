require "mqtt"

class MqttController < AuthenticatedApplicationController
  before_action :set_secrets
  before_action :validate_set_schedule_params, only: [ :set_schedule ]
  before_action :validate_send_water_signal_params, only: [ :send_water_signal ]
  before_action :authorize_user, only: [ :set_schedule, :send_water_signal ]

  def set_schedule
    message = { frequency: params[:frequency], units: params[:units] }.to_json
    publish_data(message, "#{@secrets[:topic]}/#{params[:plant_module_id]}/set_schedule")
    redirect_back fallback_location: plant_modules_path, notice: "Schedule set successfully"
  rescue => e
    redirect_back fallback_location: plant_modules_path, alert: "Error: #{e.message}"
  end

  def send_water_signal
    message = { water: true }.to_json
    publish_data(message, "#{@secrets[:topic]}/#{params[:plant_module_id]}/water")
    redirect_back fallback_location: plant_modules_path, notice: "Water signal sent successfully"
  rescue => e
    redirect_back fallback_location: plant_modules_path, alert: "Error: #{e.message}"
  end

  private

  def set_secrets
    @secrets = Rails.application.credentials.hivemq
  end

  def publish_data(message, topic)
    MQTT::Client.connect(
      host: @secrets[:url],
      port: @secrets[:port],
      username: @secrets[:username],
      password: @secrets[:password],
      ssl: true
    ) do |client|
      client.publish(topic, message)
    end
  end

  def validate_set_schedule_params
    unless params[:frequency].present? && params[:units].present? && params[:plant_module_id].present?
      redirect_back fallback_location: plant_modules_path, alert: "Missing one or more of required parameters: frequency, units, and plant_module_id"
    end
  end

  def validate_send_water_signal_params
    unless params[:plant_module_id].present?
      redirect_back fallback_location: plant_modules_path, alert: "Missing required parameter: plant_module_id"
    end
  end

  def authorize_user
    plant_module = PlantModule.find_by(id: params[:plant_module_id])

    if plant_module.nil? || plant_module.user != current_user
      redirect_back fallback_location: plant_modules_path, alert: "You are not authorized to perform this action."
    end
  end
end
