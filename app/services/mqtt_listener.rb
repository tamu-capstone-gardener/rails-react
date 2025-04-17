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
          client.subscribe("#{secrets[:topic]}/+/+/status")

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
      if value > 10000
        return
      end
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

    # Process the automatic control signals
    control_signals = ControlSignal.where(sensor_id: sensor_id, enabled: true)
    control_signals.each do |cs|
      if cs.mode == "automatic"
        condition_met = case cs.comparison
        when "<" then value < cs.threshold_value
        when ">" then value > cs.threshold_value
        else false
        end
        if condition_met
          current_time = Time.current
          last_exec = ControlExecution.where(control_signal_id: cs.id, source: "automatic").order(executed_at: :desc).first
          debounce = 300 # let's add a 5 minute debounce just in case water needs to settle in or anything similar
          if last_exec.nil? || current_time - last_exec.executed_at >= debounce
            publish_control_command(cs, mode: "automatic", status: true)
          else
            Rails.logger.info "Control signal #{cs.id} triggered recently, waiting for debounce period."
          end
        end
      end
    end
  end

  def self.publish_control_command(control_signal, options = {})
    secrets = Rails.application.credentials.hivemq
    topic = control_signal.mqtt_topic
    # Use length_ms as the toggle "on" duration (defaulting to 3000 ms if not provided)
    toggle_duration = options[:duration] || control_signal.length_ms || 3000

    if !options[:duration]
      toggle_duration /= 1000
    end

    mode = options[:mode] ? options[:mode] : control_signal.mode
    status = options[:status]

    # if the toggle duration is less than a minute, lets handle it with a thread
    if toggle_duration < 60 and toggle_duration != 0
      Rails.logger.info "Because the "
      Thread.new do
        MQTT::Client.connect(host: secrets[:url], port: secrets[:port]) do |client|
          client.publish(topic, { toggle: true }.to_json)
        end

        create_execution_data(control_signal, mode, true, toggle_duration * 1000)

        sleep(toggle_duration)

        MQTT::Client.connect(host: secrets[:url], port: secrets[:port]) do |client|
          client.publish(topic, { toggle: true }.to_json)
        end

        create_execution_data(control_signal, mode, false, 0)
      end
    else
      Rails.logger.info "Publishing #{mode} control #{status} to topic #{topic} at #{Time.current} from thread"
      MQTT::Client.connect(host: secrets[:url], port: secrets[:port]) do |client|
        client.publish(topic, { toggle: true }.to_json)
      end

      create_execution_data(control_signal, mode, status, toggle_duration * 1000)
    end
  end

  def self.next_scheduled_trigger(control_signal)
    last_exec = ControlExecution.where(control_signal_id: control_signal.id, source: "scheduled")
      .order(executed_at: :desc)
      .first


    scheduled = Time.zone.parse(control_signal.scheduled_time.strftime("%H:%M"))
    now = Time.current

    Time.use_zone("Central Time (US & Canada)") do
      if control_signal.updated_at > last_exec.executed_at
        next_trigger = scheduled
      else
        next_trigger = last_exec.executed_at + ((convert_frequency_to_ms(control_signal.frequency, control_signal.unit) || 5000) / 1000.0)
      end
      if next_trigger < now
        next_trigger = next_trigger + 1.day
      end

      Rails.logger.info "Next scheduled trigger calculated as #{next_trigger}"
      next_trigger
    end
  end

  def self.convert_frequency_to_ms(frequency, unit)
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

  def self.create_execution_data(cs, source, status, duration)
    Rails.logger.info "creating execution data for #{cs.signal_type} with source #{source} and status #{status} for duration #{duration}"
    ControlExecution.create!(
            control_signal_id: cs.id,
            source: source,
            duration_ms: duration,
            executed_at: Time.current,
            status: status
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
        responses[:sensors] << { type: type, statusduration: "exists", sensor_id: existing.id }
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
      timestamp = Time.current.iso8601

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

  def self.process_control_status(topic, message_json)
    control_type = topic.split("/")[-2]
    plant_module_id = topic.split("/")[-3]

    control_signal = ControlSignal.find_by(plant_module_id: plant_module_id, signal_type: control_type)
    return unless control_signal&.enabled?

    last_exec = ControlExecution
                  .where(control_signal_id: control_signal.id)
                  .order(executed_at: :desc)
                  .first

    last_exec_on = ControlExecution
                  .where(control_signal_id: control_signal.id, status: true)
                  .order(executed_at: :desc)
                  .first

    last_exec_off = ControlExecution
                    .where(control_signal_id: control_signal.id, status: false)
                    .order(executed_at: :desc)
                    .first

    last_updated_exec = ControlExecution
                      .where(control_signal_id: control_signal.id)
                      .order(updated_at: :desc)
                      .first

    # add a check to make sure if the esp was off at scheduled time to retrigger
    last_status = last_updated_exec.status ? "on" : "off"
    elapsed_since_on = ((last_exec_on&.updated_at || 1.year.ago) - (last_exec_on&.executed_at || 1.year.ago)) * 1000
    expected_on_duration = last_exec_on&.duration_ms || control_signal.length_ms

    if elapsed_since_on < expected_on_duration and last_status != "off"
      time_until_next_off = expected_on_duration - elapsed_since_on
      time_until_next_off /= 1000
      Rails.logger.info "Time until next off: #{time_until_next_off.to_i}s"
    else
      time_until_next_off = -1
      Rails.logger.info "Already off (time until next off == -1)"
    end


    if control_signal.mode == "scheduled"
      now = Time.current
      time_until_next_on = next_scheduled_trigger(control_signal) - now
      Rails.logger.info "Time until next on: #{time_until_next_on.to_i}s"
    end


    # see if we need to send any toggle to the ESP to either
    # a - make sure it is staying on if it is supposed to but allow for a 60 second debounce
    # b - make sure we turn stuff off when it should be turned off
    # c - turn on the scheduled stuff too
    # d - handle the most recent pushes to show successes (add notifications later maybe?)
    if last_status != message_json["status"] and time_until_next_off != -1 # a
      Rails.logger.info "The control signal is off but we expect it to be on, turn it on for #{time_until_next_off.to_i}s."
      Rails.logger.info "It will turn off at #{Time.current + time_until_next_off.to_i}"
      publish_control_command(control_signal, status: last_exec.status, duration: time_until_next_off, mode: "manual")
    elsif time_until_next_off == -1 and message_json["status"] == "on"
      Rails.logger.info "The control signal is on but we don't expect it to be, turn it off."
      publish_control_command(control_signal, status: false, duration: 0, mode: "manual")
    elsif time_until_next_off != -1 and time_until_next_off < 60 # b
      Rails.logger.info "The control signal needs to turn off in #{time_until_next_off.to_i}s"
      if time_until_next_off <= 0
        Rails.logger.error "This is unexpected behavior return safely before trying to sleep for negative time"
        return
      end
      Thread.new do
        Rails.logger.info "Waiting..."
        sleep(time_until_next_off)
        publish_control_command(control_signal, status: false, duration: 0, mode: "manual")
      end
    elsif control_signal.mode == "scheduled" and time_until_next_on > 0 and time_until_next_on < 60  # c
      Rails.logger.info "The control signal is on scheduled mode and we need to turn on the light in #{time_until_next_on.to_i}s."
      Rails.logger.info "It will turn on at #{Time.current + time_until_next_on.to_i}"
      Thread.new do
        Rails.logger.info "Waiting..."
        sleep(time_until_next_on)
        publish_control_command(control_signal, status: true, duration: control_signal.length_ms, mode: "scheduled")
      end
    elsif last_exec == last_exec_on and last_status == message_json["status"]
      Rails.logger.info "The control signal is on, as expected, so lets update the most recent on execution."
      last_exec_on&.touch
    else
      Rails.logger.info "The control signal is off, as expected, so lets update the most recent off execution."
      last_exec_off&.touch
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
