require "mqtt"

class MqttController < AuthenticatedApplicationController
  before_action :set_secrets
  before_action :validate_set_schedule_params, only: [ :set_schedule ]
  before_action :validate_send_water_signal_params, only: [ :send_water_signal ]

  def set_schedule
    message = { frequency: params[:frequency], units: params[:units] }.to_json
    publish_data(message, "#{@secrets[:topic]}/set_schedule/#{params[:sensor_id]}")
    render json: { status: "success", message: "Schedule set successfully" }
  rescue => e
    render json: { status: "error", message: e.message }, status: :unprocessable_entity
  end

  def send_water_signal
    message = { water: true }.to_json
    publish_data(message, "#{@secrets[:topic]}/water/#{params[:sensor_id]}")
    render json: { status: "success", message: "Water signal sent successfully" }
  rescue => e
    render json: { status: "error", message: e.message }, status: :unprocessable_entity
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
    unless params[:frequency].present? && params[:units].present? && params[:sensor_id].present?
      render json: { status: "error", message: "Missing one or more of required parameters: frequency, units, and sensor_id" }, status: :bad_request
    end
  end

  def validate_send_water_signal_params
    unless params[:sensor_id].present?
      render json: { status: "error", message: "Missing required parameter: sensor_id" }, status: :bad_request
    end
  end
end
