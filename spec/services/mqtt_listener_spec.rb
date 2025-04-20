# spec/services/mqtt_listener_spec.rb
require "rails_helper"
require "mqtt"

RSpec.describe MqttListener, type: :service do
  let(:user)         { User.create!(TestAttributes::User.valid) }
  let(:plant_module) { PlantModule.create!(TestAttributes::PlantModule.valid.merge(user: user)) }
  let(:sensor)       { Sensor.create!(TestAttributes::Sensor.valid.merge(plant_module: plant_module)) }

  let(:valid_sensor_topic)   { "planthub/#{sensor.id}/sensor_data" }
  let(:invalid_sensor_topic) { "planthub/invalid_format" }
  let(:valid_photo_topic)    { "planthub/#{plant_module.id}/photo" }
  let(:invalid_photo_topic)  { "planthub/invalid_format" }

  let(:valid_sensor_message)         { { "value" => 42.5, "timestamp" => "2025-02-17T12:00:00Z" } }
  let(:missing_sensor_field_message) { { "value" => 42.5 } }
  let(:binary_image_data)            { "fake_binary_image_data" }

  subject { described_class }

  before do
    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:warn)
    allow(Rails.logger).to receive(:error)
  end

  describe ".process_mqtt_sensor_data" do
    context "with a valid sensor message" do
      it "stores the sensor data correctly" do
        expect {
          subject.send(:process_mqtt_sensor_data, valid_sensor_topic, valid_sensor_message)
        }.to change(TimeSeriesDatum, :count).by(1)
        expect(Rails.logger).to have_received(:info).with("Stored time series data for sensor '#{sensor.id}'")
      end
    end

    context "with an invalid sensor topic" do
      it "ignores the message and logs a warning" do
        expect {
          subject.send(:process_mqtt_sensor_data, invalid_sensor_topic, valid_sensor_message)
        }.not_to change(TimeSeriesDatum, :count)
        expect(Rails.logger).to have_received(:warn).with("Ignoring message: Invalid topic format: #{invalid_sensor_topic}")
      end
    end

    context "with missing required fields" do
      it "does not store data and logs a warning" do
        expect {
          subject.send(:process_mqtt_sensor_data, valid_sensor_topic, missing_sensor_field_message)
        }.not_to change(TimeSeriesDatum, :count)
        expect(Rails.logger).to have_received(:warn).with("Missing required fields in message: #{missing_sensor_field_message}")
      end
    end

    context "when DB insertion fails" do
      it "rescues and logs an error" do
        allow(TimeSeriesDatum).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(TimeSeriesDatum.new))
        expect {
          subject.send(:process_mqtt_sensor_data, valid_sensor_topic, valid_sensor_message)
        }.not_to raise_error
        expect(Rails.logger).to have_received(:error).with(/Database insertion failed/)
      end
    end

    context "when value > 10000" do
      it "skips storing data" do
        high_msg = { "value" => 12_000, "timestamp" => "2025-02-17T12:00:00Z" }
        expect {
          subject.send(:process_mqtt_sensor_data, valid_sensor_topic, high_msg)
        }.not_to change(TimeSeriesDatum, :count)
      end
    end

    context "when an automatic control_signal exists and threshold is met" do
      let!(:cs) do
        ControlSignal.create!(
          id:              SecureRandom.uuid,
          plant_module:    plant_module,
          sensor_id:       sensor.id,
          signal_type:     "pump",
          enabled:         true,
          mode:            "automatic",
          comparison:      ">",
          threshold_value: 10,
          length:          1,
          length_unit:     "seconds",
          mqtt_topic:      "planthub/#{plant_module.id}/pump"
        )
      end

      before do
        allow(described_class).to receive(:publish_control_command)
      end

      it "triggers publish_control_command once" do
        msg = { "value" => 42, "timestamp" => "2025-02-17T12:00:00Z" }
        subject.send(:process_mqtt_sensor_data, valid_sensor_topic, msg)
        expect(described_class).to have_received(:publish_control_command).with(
          cs,
          hash_including(mode: "automatic", status: true)
        ).once
      end
    end
  end

  describe ".process_mqtt_photo" do
    let(:timestamp_str) { "2025-02-17T12:00:00Z" }

    before do
      allow(Time).to receive_message_chain(:current, :iso8601).and_return(timestamp_str)
      allow(SecureRandom).to receive(:uuid).and_return("test-uuid")
    end

    context "with valid binary data" do
      before do
        @photo_double  = instance_double(Photo)
        @attach_double = instance_double(ActiveStorage::Attached::One)

        allow(Photo).to receive(:new).and_return(@photo_double)
        allow(@photo_double).to receive(:image).and_return(@attach_double)
        allow(@attach_double).to receive(:attach)
        allow(@photo_double).to receive(:save!)
      end

      it "attaches and saves the photo" do
        subject.send(:process_mqtt_photo, valid_photo_topic, binary_image_data)

        expect(Photo).to have_received(:new).with(
          id:              "test-uuid",
          plant_module_id: plant_module.id.to_s,
          timestamp:       timestamp_str
        )
        expect(@attach_double).to have_received(:attach).with(
          io:           instance_of(StringIO),
          filename:     "plant_module_#{plant_module.id}_#{timestamp_str}.jpg",
          content_type: "image/jpeg"
        )
        expect(@photo_double).to have_received(:save!)
        expect(Rails.logger).to have_received(:info).with("Stored photo for plant module '#{plant_module.id}'")
      end
    end

    context "with invalid topic" do
      it "ignores and warns" do
        expect {
          subject.send(:process_mqtt_photo, invalid_photo_topic, binary_image_data)
        }.not_to change(Photo, :count)
        expect(Rails.logger).to have_received(:warn).with("Ignoring message: Invalid topic format: #{invalid_photo_topic}")
      end
    end

    context "when saving raises" do
      before do
        stub = instance_double(Photo)
        attach_stub = instance_double(ActiveStorage::Attached::One)
        allow(Photo).to receive(:new).and_return(stub)
        allow(stub).to receive(:image).and_return(attach_stub)
        allow(attach_stub).to receive(:attach)
        allow(stub).to receive(:save!).and_raise(StandardError, "boom")
      end

      it "rescues and logs error" do
        expect {
          subject.send(:process_mqtt_photo, valid_photo_topic, binary_image_data)
        }.not_to raise_error
        expect(Rails.logger).to have_received(:error).with(/Unexpected error storing data/)
      end
    end
  end

  describe ".extract_sensor_id_from_sensor_topic" do
    it "parses valid topic" do
      expect(subject.send(:extract_sensor_id_from_sensor_topic, valid_sensor_topic))
        .to eq(sensor.id.to_s)
    end

    it "returns nil for invalid topic" do
      expect(subject.send(:extract_sensor_id_from_sensor_topic, invalid_sensor_topic))
        .to be_nil
    end
  end

  describe ".extract_plant_module_id_from_photo_topic" do
    it "parses valid topic" do
      expect(subject.send(:extract_plant_module_id_from_photo_topic, valid_photo_topic))
        .to eq(plant_module.id.to_s)
    end

    it "returns nil for invalid topic" do
      expect(subject.send(:extract_plant_module_id_from_photo_topic, invalid_photo_topic))
        .to be_nil
    end
  end

  describe ".process_mqtt_sensor_init" do
    let(:topic) { "planthub/#{plant_module.id}/init_sensors" }

    context "existing sensors, new controls" do
      let(:message_json) do
        {
          "sensors"  => [ { "type" => "moisture" } ],
          "controls" => [ { "type" => "pump", "label" => "Pump" } ]
        }
      end

      before do
        plant_module.sensors.create!(
          id: SecureRandom.uuid,
          measurement_type: "moisture",
          measurement_unit: "lux"
        )
        allow(described_class).to receive(:publish_sensor_response)
      end

      it "creates control and publishes response" do
        subject.send(:process_mqtt_sensor_init, topic, message_json)

        cs = plant_module.control_signals.find_by(signal_type: "pump")
        expected = {
          sensors: [
            { type: "moisture", status: "exists", sensor_id: plant_module.sensors.find_by(measurement_type: "moisture").id }
          ],
          controls: [
            { type: "pump", status: "created", control_id: cs.id }
          ]
        }

        expect(described_class).to have_received(:publish_sensor_response).with(
          plant_module.id.to_s, expected
        )
      end
    end
  end

  describe ".publish_control_command" do
    let(:dummy_client) { instance_double("MQTT::Client", publish: true) }
    let(:creds)        { { url: "broker.test", port: 1883 } }

    before do
      allow(Rails.application.credentials).to receive(:hivemq).and_return(creds)
      allow(MQTT::Client).to receive(:connect).and_yield(dummy_client)
      allow(described_class).to receive(:format_duration_to_seconds).with(120, "seconds").and_return(120)
      allow(described_class).to receive(:format_duration_from_seconds).with(120, "seconds").and_return(120)
      allow(described_class).to receive(:create_execution_data)
    end

    let(:control_signal) do
      instance_double("ControlSignal",
        mqtt_topic:  "planthub/XYZ/control",
        length_unit: "seconds",
        length:      120,
        mode:        "scheduled"
      )
    end

    it "publishes once and records execution when ≥ 60s" do
      subject.send(:publish_control_command, control_signal, status: true)

      expect(MQTT::Client).to have_received(:connect).with(host: creds[:url], port: creds[:port])
      expect(dummy_client).to have_received(:publish).with("planthub/XYZ/control")
      expect(described_class).to have_received(:create_execution_data).with(
        control_signal, "scheduled", true, 120, "seconds"
      )
    end
  end

  describe ".extract_module_id" do
    it "grabs the correct ID" do
      expect(described_class.send(:extract_module_id, "planthub/XYZ/init_sensors", "init_sensors"))
        .to eq("XYZ")
    end

    it "returns nil for wrong suffix" do
      expect(described_class.send(:extract_module_id, "planthub/XYZ/photo", "init_sensors"))
        .to be_nil
    end
  end

  describe ".default_unit_for" do
    it "maps known types" do
      expect(described_class.send(:default_unit_for, "temperature")).to eq("Celsius")
      expect(described_class.send(:default_unit_for, "light_analog")).to eq("lux")
    end

    it "falls back to unknown" do
      expect(described_class.send(:default_unit_for, "foo_bar")).to eq("unknown")
    end
  end

  describe ".publish_control_command when < 60s" do
    let(:dummy_client) { instance_double("MQTT::Client", publish: true) }
    let(:creds)        { { url: "broker.test", port: 1883 } }
    let(:small_cs) do
      instance_double("ControlSignal",
        mqtt_topic:  "planthub/XYZ/control",
        length:      10,
        length_unit: "seconds",
        mode:        "manual"
      )
    end

    before do
      allow(Rails.application.credentials).to receive(:hivemq).and_return(creds)
      allow(described_class).to receive(:format_duration_to_seconds).with(10, "seconds").and_return(10)
      allow(described_class).to receive(:format_duration_from_seconds).with(10, "seconds").and_return(10)
      # stub Thread.new so block never runs sleep
      allow(Thread).to receive(:new).and_return(double)
      allow(MQTT::Client).to receive(:connect).and_yield(dummy_client)
      allow(described_class).to receive(:create_execution_data)
    end

    it "issues on/off and logs executions twice" do
      described_class.send(:publish_control_command, small_cs, status: true, mode: "manual")

      expect(MQTT::Client).to have_received(:connect).twice
      expect(described_class).to have_received(:create_execution_data).twice
    end
  end

  describe ".next_scheduled_trigger" do
    let(:now)         { Time.zone.local(2025, 4, 19, 12, 0, 0) }
    let(:today_sched) { Time.zone.local(2025, 4, 19, 6, 0, 0) }
    let(:cs) do
      instance_double("ControlSignal",
        id:             "cs-id",
        scheduled_time: today_sched,
        updated_at:     now - 1.hour,
        frequency:      1,
        unit:           "days"
      )
    end
    let(:last_exec) { instance_double("ControlExecution", executed_at: today_sched - 2.days) }

    before do
      allow(Time).to receive(:current).and_return(now)
      allow(ControlExecution).to receive_message_chain(:where, :order, :first).and_return(last_exec)
      allow(described_class).to receive(:format_duration_to_seconds).with(1, "days").and_return(86_400)
    end

    it "rolls over when today's time has passed" do
      next_trigger = described_class.send(:next_scheduled_trigger, cs)
      expect(next_trigger.to_date).to eq((now + 1.day).to_date)
    end
  end

  describe ".create_execution_data" do
    let(:cs) { instance_double("ControlSignal", id: "cs-id", signal_type: "pump") }

    it "creates a new ControlExecution" do
      expect(Rails.logger).to receive(:info).with(/creating execution data for pump/)
      expect(ControlExecution).to receive(:create!).with(
        control_signal_id: "cs-id",
        source:            "test-source",
        status:            false,
        duration:          5,
        duration_unit:     "secs",
        executed_at:       kind_of(Time)
      )
      described_class.send(:create_execution_data, cs, "test-source", false, 5, "secs")
    end
  end

  describe ".process_control_status" do
    let(:user)         { User.create!(TestAttributes::User.valid) }
    let(:plant_module) { PlantModule.create!(TestAttributes::PlantModule.valid.merge(user: user)) }
    let!(:cs) do
      ControlSignal.create!(
        id:              SecureRandom.uuid,
        plant_module:    plant_module,
        signal_type:     "pump",
        mqtt_topic:      "planthub/#{plant_module.id}/pump",
        length:          30,
        length_unit:     "seconds",
        enabled:         true,
        mode:            "manual"
      )
    end

    before do
      @last_on = ControlExecution.create!(
        control_signal_id: cs.id,
        source:            "manual",
        status:            true,
        duration:          30,
        duration_unit:     "seconds",
        executed_at:       10.seconds.ago
      )
      @last_on.touch
      allow(described_class).to receive(:publish_control_command)
      allow(described_class).to receive(:format_duration_to_seconds).and_return(30)
    end

    context "when reported off but expected on" do
      it "reissues the command" do
        described_class.send(
          :process_control_status,
          "planthub/#{plant_module.id}/pump/status",
          { "status" => "off" }
        )
        expect(described_class).to have_received(:publish_control_command).with(
          cs,
          hash_including(status: true, mode: "manual")
        )
      end
    end

    context "when scheduled mode and next on is imminent" do
      before do
        cs.update!(mode: "scheduled")
        allow(described_class).to receive(:next_scheduled_trigger).and_return(Time.current + 30.seconds)
        # stub Thread.new so block never runs sleep
        allow(Thread).to receive(:new).and_return(double)
      end

      it "spawns a thread and calls publish_control_command" do
        described_class.send(
          :process_control_status,
          "planthub/#{plant_module.id}/pump/status",
          { "status" => "on" }
        )
        expect(Thread).to have_received(:new)
        expect(described_class).to have_received(:publish_control_command)
      end
    end
  end
end
