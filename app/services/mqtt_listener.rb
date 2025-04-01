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
          client.subscribe("#{secrets[:topic]}/+/init_sensors")

          client.get do |topic, message|
            Rails.logger.info "Received MQTT message on #{topic}: #{message}"

            message_json = JSON.parse(message) rescue nil
            unless message_json.is_a?(Hash)
              Rails.logger.error "Malformed JSON received: #{message}"
              next
            end

            if topic.end_with?("sensor_data")
              process_mqtt_sensor_data(topic, message_json)
            elsif topic.include?("init_sensors")
              process_mqtt_sensor_init(topic, message_json)
            elsif topic.include?("sensor_init_response")
              Rails.logger.info "Received sensor init response: #{message_json}"
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

      Rails.logger.info("Trying to get value in MQTTListener")

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

    def self.process_mqtt_sensor_init(topic, message_json)
      plant_module_id = extract_module_id(topic, "init_sensors")
      Rails.logger.info "Received sensor init message for plant_module #{plant_module_id}: #{message_json.inspect}"
      plant_module = PlantModule.find_by(id: plant_module_id)
      unless plant_module
        Rails.logger.error "Plant module not found for id #{plant_module_id}"
        return
      end

      sensors = message_json["sensors"] || []
      controls = message_json["controls"] || []
      responses = { sensors: [], controls: [] }

      sensors.each do |sensor_data|
        type = sensor_data["type"]
        unit = sensor_data["unit"] || default_unit_for(type)
        existing = plant_module.sensors.find_by(measurement_type: type)
        if existing
          Rails.logger.info "Sensor for type '#{type}' already exists (ID: #{existing.id})."
          responses[:sensors] << { type: type, status: "exists", sensor_id: existing.id }
        else
          Rails.logger.info "Creating new sensor for type '#{type}' with unit '#{unit}'."
          sensor = plant_module.sensors.create!(
            id: SecureRandom.uuid,
            measurement_type: type,
            measurement_unit: unit
          )
          responses[:sensors] << { type: type, status: "created", sensor_id: sensor.id }
        end
      end

      controls.each do |control|
        type = control["type"]
        existing = plant_module.control_signals.find_by(signal_type: type)
        if existing
          Rails.logger.info "Control signal for type '#{type}' already exists (ID: #{existing.id})."
          responses[:controls] << { type: type, status: "exists", control_id: existing.id }
        else
          Rails.logger.info "Creating new control signal for type '#{type}'."
          signal = plant_module.control_signals.create!(
            id: SecureRandom.uuid,
            signal_type: type,
            label: control["label"] || type.titleize,
            mqtt_topic: "planthub/#{plant_module_id}/#{type}"
          )
          responses[:controls] << { type: type, status: "created", control_id: signal.id }
        end
      end

      Rails.logger.info "Sensor init process completed. Responses: #{responses.to_json}"
      publish_sensor_response(plant_module_id, responses)
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

    def self.default_unit_for(type)
      {
        "moisture" => "analog",
        "temperature" => "Celsius",
        "humidity" => "%",
        "light" => "lux"
      }[type] || "unknown"
    end

    def self.extract_sensor_id_from_sensor_topic(path)
      match = path.match(%r{\Aplanthub/([\w-]+)/sensor_data\z})
      match ? match[1] : nil
    end

    def self.extract_plant_module_id_from_photo_topic(path)
      match = path.match(%r{\Aplanthub/([\w-]+)/photo\z})
      match ? match[1] : nil
    end

    def self.extract_module_id(topic, suffix)
      match = topic.match(%r{planthub/(.*?)/#{suffix}})
      match ? match[1] : nil
    end

    def self.publish_sensor_response(module_id, responses)
      Rails.logger.info("Attempting to publish a sensor init response!")
      MQTT::Client.connect(host: Rails.application.credentials.hivemq[:url], port: Rails.application.credentials.hivemq[:port]) do |client|
        client.publish("planthub/#{module_id}/sensor_init_response", responses.to_json)
      end
    end
end
