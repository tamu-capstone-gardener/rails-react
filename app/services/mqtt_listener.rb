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
            if topic.end_with?("photo")
              Rails.logger.info "Received MQTT binary photo data on #{topic}"
              process_mqtt_photo(topic, message)
            else
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
              else
                Rails.logger.info "Received sensor init response: #{message_json}"
              end
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
    unless sensor_id
      Rails.logger.warn "Ignoring message: Invalid topic format: #{topic}"
      return
    end

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
          last_exec = ControlExecution.where(control_signal_id: cs.id, source: "auto").order(executed_at: :desc).first
          debounce = 300 # let's add a 5 minute debounce just in case water needs to settle in or anything similar
          if last_exec.nil? || current_time - last_exec.executed_at >= debounce
            publish_control_command(cs, mode: "auto")
          else
            Rails.logger.info "Control signal #{cs.id} triggered recently, waiting for debounce period."
          end
        end
      when "scheduled"
        current_time = Time.now
        next_trigger = next_scheduled_trigger(cs)
        last_exec = ControlExecution.where(control_signal_id: cs.id, source: "scheduled").order(executed_at: :desc).first
        local_now = Time.now
        Time.use_zone("Central Time (US & Canada)") do
          local_next_trigger = next_trigger
          difference = local_next_trigger - local_now
          Rails.logger.info "next_trigger - current_time: #{next_trigger - current_time} and difference: #{difference}"
          if (difference).abs <= 60
            publish_control_command(cs, mode: "scheduled")
          else
            Rails.logger.info "Control signal #{cs.id} has next_trigger: #{next_trigger} and current time: #{current_time}, this means it falls outside the threshold."
          end
        end
      end
    end
  end

  def self.publish_control_command(control_signal, options = {})
    secrets = Rails.application.credentials.hivemq
    topic = control_signal.mqtt_topic
    # Use length_ms as the toggle "on" duration (defaulting to 3000 ms if not provided)
    toggle_duration = control_signal.length_ms || 3000

    mode = options[:mode] || control_signal.mode
    Rails.logger.info "publish_control_command invoked for control_signal #{control_signal.id} with mode #{mode}, scheduled_time: #{control_signal.scheduled_time}, frequency: #{control_signal.frequency}, unit: #{control_signal.unit}, toggle_duration: #{toggle_duration / 1000.0}s"


    if mode == "scheduled"
      Thread.new do
        begin
          # Publish the "toggle on" command.
          Rails.logger.info "Publishing scheduled control ON to topic #{topic} at #{Time.current} from thread"
          MQTT::Client.connect(host: secrets[:url], port: secrets[:port]) do |client|
            client.publish(topic, { toggle: true }.to_json)
          end

          create_execution_data(control_signal, mode)
          # Keep the toggle on for the duration specified (toggle_duration is in milliseconds).
          Rails.logger.info("Sleeping for #{toggle_duration / 1000.0}s before toggling back off")
          sleep(toggle_duration / 1000.0)

          # Publish the "toggle off" command (or the second toggle as needed).
          Rails.logger.info "Publishing scheduled control OFF to topic #{topic} at #{Time.current}"
          MQTT::Client.connect(host: secrets[:url], port: secrets[:port]) do |client|
            client.publish(topic, { toggle: true }.to_json)
          end

          break
        rescue => thread_e
          Rails.logger.error "Error in scheduled command thread: #{thread_e.message}"
          # Optionally, you can choose to break or retry immediately.
        end
      end
    elsif mode == "manual"
      Thread.new do
        begin
          # Publish the "toggle on" command.
          Rails.logger.info "Publishing scheduled control ON to topic #{topic} at #{Time.current} from thread"
          MQTT::Client.connect(host: secrets[:url], port: secrets[:port]) do |client|
            client.publish(topic, { toggle: true }.to_json)
          end

          create_execution_data(control_signal, mode)
          # Keep the toggle on for the duration specified (toggle_duration is in milliseconds).
          Rails.logger.info("Sleeping for #{toggle_duration / 1000.0}s before toggling back off")
          sleep(toggle_duration / 1000.0)

          # Publish the "toggle off" command (or the second toggle as needed).
          Rails.logger.info "Publishing scheduled control OFF to topic #{topic} at #{Time.current}"
          MQTT::Client.connect(host: secrets[:url], port: secrets[:port]) do |client|
            client.publish(topic, { toggle: true }.to_json)
          end

          break
        rescue => thread_e
          Rails.logger.error "Error in scheduled command thread: #{thread_e.message}"
          # Optionally, you can choose to break or retry immediately.
        end
      end
    else
      Thread.new do
        begin
          # Publish the "toggle on" command.
          Rails.logger.info "Publishing scheduled control ON to topic #{topic} at #{Time.current} from thread"
          MQTT::Client.connect(host: secrets[:url], port: secrets[:port]) do |client|
            client.publish(topic, { toggle: true }.to_json)
          end

          create_execution_data(control_signal, mode)
          # Keep the toggle on for the duration specified (toggle_duration is in milliseconds).
          Rails.logger.info("Sleeping for #{toggle_duration / 1000.0}s before toggling back off")
          sleep(toggle_duration / 1000.0)

          # Publish the "toggle off" command (or the second toggle as needed).
          Rails.logger.info "Publishing scheduled control OFF to topic #{topic} at #{Time.current}"
          MQTT::Client.connect(host: secrets[:url], port: secrets[:port]) do |client|
            client.publish(topic, { toggle: true }.to_json)
          end

          break
        rescue => thread_e
          Rails.logger.error "Error in scheduled command thread: #{thread_e.message}"
          # Optionally, you can choose to break or retry immediately.
        end
      end
    end
  end

  def self.next_scheduled_trigger(control_signal)
    last_exec = ControlExecution.where(control_signal_id: control_signal.id, source: "scheduled")
      .order(executed_at: :desc)
      .first
    now = Time.now
    scheduled_time_local = control_signal.scheduled_time
    Time.use_zone("Central Time (US & Canada)") do
      today_scheduled_time = now.change(hour: scheduled_time_local.hour, min: scheduled_time_local.min, sec: scheduled_time_local.sec)
      tomorrow_scheduled_time = today_scheduled_time + 1.day
      # Rails.logger.info "last_exec: #{last_exec.executed_at}; now: #{now}; scheduled_time_local: #{today_scheduled_time}; tomorrow_scheduled_time: #{tomorrow_scheduled_time}"
      if last_exec.present?
        if last_exec.executed_at < control_signal.updated_at
          if (now - today_scheduled_time).abs > 60
            Rails.logger.info "Next scheduled trigger calculated as #{tomorrow_scheduled_time}"
            return tomorrow_scheduled_time
          else
            Rails.logger.info "Next scheduled trigger calculated as #{today_scheduled_time}"
            return today_scheduled_time
          end
        else
          next_trigger = last_exec.executed_at + ((convert_frequency_to_ms(control_signal.frequency, control_signal.unit) || 5000) / 1000.0)
        end
      else
        next_trigger = today_scheduled_time
        next_trigger += 1.day if next_trigger < now
      end

      Rails.logger.info "Next scheduled trigger calculated as #{next_trigger}"
      next_trigger
    end
  end

  def self.convert_frequency_to_ms(frequency, unit)
    Rails.logger.info "Converting frequency to ms: frequency=#{frequency}, unit=#{unit}"
    case unit
    when "minutes"
      frequency * 60 * 1000
    when "hours"
      frequency * 60 * 60 * 1000
    when "days"
      frequency * 24 * 60 * 60 * 1000
    else
      frequency * 60 * 1000  # default to minutes if unspecified
    end
  end

  def self.create_execution_data(cs, source)
    ControlExecution.create!(
            control_signal_id: cs.id,
            source: source,
            duration_ms: cs.length_ms || 3000,
            executed_at: Time.now
          )
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

  def self.process_mqtt_photo(topic, message)
    plant_module_id = extract_plant_module_id_from_photo_topic(topic)
    unless plant_module_id
      Rails.logger.warn "Ignoring message: Invalid topic format: #{topic}"
      return
    end

    begin
      # Use StringIO instead of Tempfile to keep the data in memory
      io = StringIO.new(message)
      timestamp = Time.now.iso8601

      photo = Photo.new(
        id: SecureRandom.uuid,
        plant_module_id: plant_module_id,
        timestamp: timestamp
      )

      photo.image.attach(
        io: io,
        filename: "plant_module_#{plant_module_id}_#{timestamp}.jpg",
        content_type: "image/jpeg"
      )

      photo.save!
      Rails.logger.info "Stored photo for plant module '#{plant_module_id}'"
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "Database insertion failed when uploading photo for plant module #{plant_module_id}."
    rescue => e
      Rails.logger.error "Unexpected error storing data for plant module #{plant_module_id}."
    end
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

  def self.default_unit_for(type)
    {
      "moisture" => "analog",
      "temperature" => "Celsius",
      "humidity" => "%",
      "light_analog" => "lux"
    }[type] || "unknown"
  end
end
