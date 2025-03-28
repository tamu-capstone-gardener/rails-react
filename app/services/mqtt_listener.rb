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
        ) do |client|
          Rails.logger.info "Connected to MQTT broker at #{secrets[:url]}"

          client.subscribe("#{secrets[:topic]}/+/sensor_data")
          client.subscribe("#{secrets[:topic]}/+/photo")

          client.get do |topic, message|
            Rails.logger.info "Received MQTT message on #{topic}: #{message}"

            message_json = JSON.parse(message) rescue nil
            unless message_json.is_a?(Hash)
              Rails.logger.error "Malformed JSON received: #{message}"
              next
            end

            if topic.end_with?("sensor_data")
              process_mqtt_sensor_data(topic, message_json)
            else
              process_mqtt_photo(topic, message_json)
            end
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

  private
    def self.process_mqtt_sensor_data(topic, message_json)
      sensor_id = extract_sensor_id_from_sensor_topic(topic)
      unless sensor_id
        Rails.logger.warn "Ignoring message: Invalid topic format: #{topic}"
        return
      end

      Rails.logger.error("Trying to get value in MQTTListener")

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

    def self.process_mqtt_photo(topic, message_json)
      plant_module_id = extract_plant_module_id_from_photo_topic(topic)
      unless plant_module_id
        Rails.logger.warn "Ignoring message: Invalid topic format: #{topic}"
        return
      end

      url = message_json["url"]
      timestamp = message_json["timestamp"]

      if url.nil? || timestamp.nil?
        Rails.logger.warn "Missing required fields in message: #{message_json}"
        return
      end

      begin
        Photo.create!(
          id: SecureRandom.uuid,
          plant_module_id: plant_module_id,
          timestamp: timestamp,
          url: url
        )
        Rails.logger.info "Stored photo for plant module '#{plant_module_id}'"
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error "Database insertion failed: #{e.message}. Data: #{message_json}"
      rescue => e
        Rails.logger.error "Unexpected error storing data: #{e.message}"
      end
    end

    def self.extract_sensor_id_from_sensor_topic(path)
      match = path.match(%r{\Aplanthub/([\w-]+)/sensor_data\z})
      match ? match[1] : nil
    end

    def self.extract_plant_module_id_from_photo_topic(path)
      match = path.match(%r{\Aplanthub/([\w-]+)/photo\z})
      match ? match[1] : nil
    end
end
