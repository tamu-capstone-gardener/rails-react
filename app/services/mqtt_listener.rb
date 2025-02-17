require "mqtt"

class MqttListener
  def self.start
    secrets = Rails.application.credentials.hivemq

    Rails.logger.info "Starting MQTT subscriber on #{secrets[:topic]}..."

    loop do
      begin
        MQTT::Client.connect(
          host: secrets[:url],
          port: secrets[:port],
          username: secrets[:username],
          password: secrets[:password],
          ssl: true
        ) do |client|
          Rails.logger.info "Connected to MQTT broker at #{secrets[:url]}"

          client.subscribe("#{secrets[:topic]}/sensor_data/#")

          client.get do |topic, message|
            process_mqtt_message(topic, message)
          end
        end
      rescue MQTT::Exception, SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH => e
        Rails.logger.error "MQTT connection error: #{e.message}, retrying in 5 seconds..."
        sleep 5
      rescue => e
        Rails.logger.fatal "Unexpected MQTT Listener error: #{e.message}, retrying in 5 seconds..."
        sleep 5
      end
    end
  end

  def self.process_mqtt_message(topic, message)
    Rails.logger.info "Received MQTT message on #{topic}: #{message}"

    sensor_id = extract_sensor_id_from_topic(topic)
    unless sensor_id
      Rails.logger.warn "Ignoring message: Invalid topic format: #{topic}"
      return
    end

    message_json = JSON.parse(message) rescue nil
    unless message_json.is_a?(Hash)
      Rails.logger.error "Malformed JSON received: #{message}"
      return
    end

    value = message_json["value"]
    timestamp = message_json["timestamp"]

    if value.nil? || timestamp.nil?
      Rails.logger.warn "Missing required fields in message: #{message_json}"
      return
    end

    begin
      TimeSeriesDatum.create!(
        sensor_id: sensor_id,
        value: value,
        timestamp: timestamp
      )
      Rails.logger.info "Stored time series data for sensor '#{sensor_id}'"
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "Database insertion failed: #{e.message}. Data: #{message_json}"
    rescue => e
      Rails.logger.error "Unexpected error storing data: #{e.message}"
    end
  end

  def self.extract_sensor_id_from_topic(path)
    match = path.match(%r{\Aplanthub/sensor_data/([\w-]+)\z}) # Accepts alphanumeric and hyphens
    match ? match[1] : nil
  end
end
