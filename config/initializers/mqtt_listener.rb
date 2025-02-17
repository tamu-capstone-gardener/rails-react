require "mqtt"

def extract_sensor_id_from_topic(path)
  match = path.match(%r{\Aplanthub/sensor_data/(\d+)\z})
  match ? match[1] : nil
end

Thread.new do
  secrets = Rails.application.credentials.hivemq

  Rails.logger.info "Starting MQTT subscriber on #{secrets[:topic]}..."

  begin
    MQTT::Client.connect(
      host: secrets[:url],
      port: secrets[:port],
      username: secrets[:username],
      password: secrets[:password],
      ssl: true
    ) do |client|
      client.subscribe("#{secrets[:topic]}/#")
      client.get do |topic, message|
        Rails.logger.info "Received MQTT message on #{topic}: #{message}"
        sensor_id = extract_sensor_id_from_topic(topic)
        next unless sensor_id
        message_json = JSON.parse(message)

        TimeSeriesDatum.create!(
          sensor_id: sensor_id,
          value: message_json["value"],
          timestamp: message_json["timestamp"]
        )
      end
    end
  rescue => e
    Rails.logger.error "MQTT Listener error: #{e.message}"
    sleep 5
    retry
  end
end
