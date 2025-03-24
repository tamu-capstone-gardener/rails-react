require "rails_helper"
require "mqtt"

RSpec.describe MqttListener, type: :service do
  let(:user) { User.create!(TestAttributes::User.valid) }
  let(:plant_module) { PlantModule.create!(TestAttributes::PlantModule.valid.merge(user: user)) }
  let(:sensor) { Sensor.create!(TestAttributes::Sensor.valid.merge(plant_module: plant_module)) }

  # Topics for sensor data
  let(:valid_sensor_topic)   { "planthub/#{sensor.id}/sensor_data" }
  let(:invalid_sensor_topic) { "planthub/invalid_format" }

  # Topics for photo data
  let(:valid_photo_topic)    { "planthub/#{plant_module.id}/photo" }
  let(:invalid_photo_topic)  { "planthub/invalid_format" }

  # Message payloads for sensor data
  let(:valid_sensor_message)         { { "value" => 42.5, "timestamp" => "2025-02-17T12:00:00Z" } }
  let(:missing_sensor_field_message) { { "value" => 42.5 } }

  # Message payloads for photo data
  let(:valid_photo_message)         { { "url" => "http://example.com/photo.jpg", "timestamp" => "2025-02-17T12:00:00Z" } }
  let(:missing_photo_field_message) { { "url" => "http://example.com/photo.jpg" } }

  # Since the helper methods are now class methods, we set the subject as the class itself.
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

    context "with missing required fields in sensor message" do
      it "does not store data and logs a warning" do
        expect {
          subject.send(:process_mqtt_sensor_data, valid_sensor_topic, missing_sensor_field_message)
        }.not_to change(TimeSeriesDatum, :count)
        expect(Rails.logger).to have_received(:warn).with("Missing required fields in message: #{missing_sensor_field_message}")
      end
    end

    context "when database insertion fails for sensor data" do
      it "handles the exception and logs an error" do
        allow(TimeSeriesDatum).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(TimeSeriesDatum.new))
        expect {
          subject.send(:process_mqtt_sensor_data, valid_sensor_topic, valid_sensor_message)
        }.not_to raise_error
        expect(Rails.logger).to have_received(:error).with(/Database insertion failed/)
      end
    end
  end

  describe ".process_mqtt_photo" do
    context "with a valid photo message" do
      it "stores the photo data correctly" do
        expect {
          subject.send(:process_mqtt_photo, valid_photo_topic, valid_photo_message)
        }.to change(Photo, :count).by(1)
        expect(Rails.logger).to have_received(:info).with("Stored photo for plant module '#{plant_module.id}'")
      end
    end

    context "with an invalid photo topic" do
      it "ignores the message and logs a warning" do
        expect {
          subject.send(:process_mqtt_photo, invalid_photo_topic, valid_photo_message)
        }.not_to change(Photo, :count)
        expect(Rails.logger).to have_received(:warn).with("Ignoring message: Invalid topic format: #{invalid_photo_topic}")
      end
    end

    context "with missing required fields in photo message" do
      it "does not store data and logs a warning" do
        expect {
          subject.send(:process_mqtt_photo, valid_photo_topic, missing_photo_field_message)
        }.not_to change(Photo, :count)
        expect(Rails.logger).to have_received(:warn).with("Missing required fields in message: #{missing_photo_field_message}")
      end
    end

    context "when database insertion fails for photo data" do
      it "handles the exception and logs an error" do
        allow(Photo).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(Photo.new))
        expect {
          subject.send(:process_mqtt_photo, valid_photo_topic, valid_photo_message)
        }.not_to raise_error
        expect(Rails.logger).to have_received(:error).with(/Database insertion failed/)
      end
    end
  end

  describe ".extract_sensor_id_from_sensor_topic" do
    it "extracts the sensor ID correctly from a valid topic" do
      sensor_id = subject.send(:extract_sensor_id_from_sensor_topic, valid_sensor_topic)
      expect(sensor_id).to eq(sensor.id.to_s)
    end

    it "returns nil for an invalid sensor topic format" do
      sensor_id = subject.send(:extract_sensor_id_from_sensor_topic, invalid_sensor_topic)
      expect(sensor_id).to be_nil
    end
  end

  describe ".extract_plant_module_id_from_photo_topic" do
    it "extracts the plant module ID correctly from a valid topic" do
      plant_module_id = subject.send(:extract_plant_module_id_from_photo_topic, valid_photo_topic)
      expect(plant_module_id).to eq(plant_module.id.to_s)
    end

    it "returns nil for an invalid photo topic format" do
      plant_module_id = subject.send(:extract_plant_module_id_from_photo_topic, invalid_photo_topic)
      expect(plant_module_id).to be_nil
    end
  end
end
