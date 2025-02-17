require 'mqtt'

class MqttController < ApplicationController
  def publish_data
    topic = "plant_hub/sensor_data"
    message = { sensor_id: params[:sensor_id], value: params[:value] }.to_json
    MQTT::Client.connect('mqtt://your-mqtt-broker') do |client|
      client.publish(topic, message)
    end
    render json: { status: 'success', message: 'Data published' }
  end
end
