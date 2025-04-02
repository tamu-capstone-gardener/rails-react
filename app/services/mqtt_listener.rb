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

  # Process incoming sensor data, trigger automatic and scheduled control signals.
  def self.process_mqtt_sensor_data(topic, message_json)
    sensor_id = extract_sensor_id_from_sensor_topic(topic)
    Rails.logger.info("Processing sensor data for sensor: #{sensor_id}")

    value = message_json["value"]
    timestamp = message_json["timestamp"]

    if value.nil? || timestamp.nil?
      Rails.logger.warn "Missing required fields in message: #{message_json}"
      return
    end

    # Store the sensor data
    begin
      TimeSeriesDatum.create!(
        sensor_id: sensor_id,
        value: value,
        timestamp: timestamp
      )
      Rails.logger.info "Stored time series data for sensor '#{sensor_id}'"
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "Database insertion failed: #{e.message}. Data: #{message_json}"
      return
    end

    # Process control signals for this sensor
    control_signals = ControlSignal.where(sensor_id: sensor_id, enabled: true)
    control_signals.each do |cs|
      case cs.mode
      when "automatic"
        condition_met = case cs.comparison
        when "<" then value < cs.threshold_value
        when ">" then value > cs.threshold_value
        else false
        end
        if condition_met
          current_time = Time.now
          last_exec = ControlExecution.where(control_signal_id: cs.id).order(executed_at: :desc).first
          delay_ms = cs.delay || 3000
          if last_exec.nil? || ((current_time - last_exec.executed_at) * 1000) >= delay_ms
            Rails.logger.info "Automatic control triggered for control signal #{cs.id} (#{cs.signal_type})"
            publish_control_command(cs, auto: true)
            ControlExecution.create!(
              control_signal_id: cs.id,
              source: "auto",
              duration_ms: cs.length_ms || delay_ms,
              executed_at: current_time
            )
          else
            Rails.logger.info "Control signal #{cs.id} triggered recently, waiting for delay period."
          end
        end
      when "scheduled"
        # For scheduled mode, trigger based on frequency regardless of sensor value.
        # Here we assume `frequency` is provided in seconds.
        scheduled_interval_ms = (cs.frequency || 60) * 1000
        current_time = Time.now
        last_exec = ControlExecution.where(control_signal_id: cs.id).order(executed_at: :desc).first
        if last_exec.nil? || ((current_time - last_exec.executed_at) * 1000) >= scheduled_interval_ms
          Rails.logger.info "Scheduled control triggered for control signal #{cs.id} (#{cs.signal_type})"
          publish_control_command(cs, scheduled: true)
          ControlExecution.create!(
            control_signal_id: cs.id,
            source: "scheduled",
            duration_ms: cs.length_ms || cs.delay || 3000,
            executed_at: current_time
          )
        end
      when "manual"
        # In manual mode, the control is triggered by an explicit command, not by sensor data.
        Rails.logger.debug "Control signal #{cs.id} is in manual mode; no auto trigger."
      end
    end
  end

  # Publishes the MQTT command for a control signal.
  # The options hash can include flags such as :auto or :scheduled.
  def self.publish_control_command(control_signal, options = {})
    secrets = Rails.application.credentials.hivemq
    topic = control_signal.mqtt_topic
    message = {
      duration: control_signal.length_ms || control_signal.delay || 3000,
      auto: options[:auto] || false,
      scheduled: options[:scheduled] || false
    }.to_json

    MQTT::Client.connect(
      host: secrets[:url],
      port: secrets[:port]
    ) do |client|
      client.publish(topic, message)
    end
    Rails.logger.info "Published control command to topic #{topic} with message #{message}"
  end

  def self.process_mqtt_sensor_init(topic, message_json)
    # ...existing sensor initialization code...
  end

  def self.process_mqtt_photo(topic, message_json)
    # ...existing photo processing code...
  end

  def self.extract_sensor_id_from_sensor_topic(path)
    match = path.match(%r{\Aplanthub/([\w-]+)/sensor_data\z})
    match ? match[1] : nil
  end

  def self.extract_module_id(topic, suffix)
    match = topic.match(%r{planthub/(.*?)/#{suffix}})
    match ? match[1] : nil
  end

  def self.extract_plant_module_id_from_photo_topic(path)
    match = path.match(%r{\Aplanthub/([\w-]+)/photo\z})
    match ? match[1] : nil
  end

  def self.publish_sensor_response(module_id, responses)
    Rails.logger.info("Attempting to publish a sensor init response!")
    MQTT::Client.connect(
      host: Rails.application.credentials.hivemq[:url],
      port: Rails.application.credentials.hivemq[:port]
    ) do |client|
      client.publish("planthub/#{module_id}/sensor_init_response", responses.to_json)
    end
  end
end
