require "mqtt"

class MqttController < ApplicationController
  # Needed for "public" APIs
  skip_before_action :verify_authenticity_token

  # TODO
  # From server -> device
  # Send signals to water, change schedule of watering
  # From device <- server
  # Low battery information, low water information, sensor data

  def publish_data
    message = { sensor_id: params[:sensor_id], value: params[:value] }.to_json
    secrets = Rails.application.credentials.hivemq
    MQTT::Client.connect(
      host: secrets[:url],
      port: secrets[:port],
      username: secrets[:username],
      password: secrets[:password],
      ssl: true
    ) do |client|
      client.publish(secrets[:topic], message)
    end
    render json: { status: "success", message: "Data published" }
  end
end
