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

  # Binary image data for photo tests
  let(:binary_image_data) { "fake_binary_image_data" }

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
    context "with valid binary image data" do
      let(:fixed_time) { Time.utc(2025, 2, 17, 12, 0, 0) }
      let(:timestamp_str) { "2025-02-17T12:00:00Z" }

      before do
        # Set up a full mock for StringIO
        allow(StringIO).to receive(:new).with(binary_image_data).and_return(double('StringIO'))

        # Set up the UUID
        allow(SecureRandom).to receive(:uuid).and_return("test-uuid")

        # Set up the timestamp
        allow(Time).to receive(:now).and_return(fixed_time)
        allow(fixed_time).to receive(:iso8601).and_return(timestamp_str)

        # Creating a photo instance with properly stubbed attachment
        photo_mock = instance_double(Photo)
        image_mock = instance_double(ActiveStorage::Attached::One)

        allow(Photo).to receive(:new).and_return(photo_mock)
        allow(photo_mock).to receive(:image).and_return(image_mock)
        allow(image_mock).to receive(:attach)
        allow(photo_mock).to receive(:save!)
        allow(photo_mock).to receive(:id).and_return("test-uuid")
        allow(photo_mock).to receive(:plant_module_id).and_return(plant_module.id.to_s)
        allow(photo_mock).to receive(:timestamp).and_return(timestamp_str)
      end

      it "stores the photo correctly" do
        result = subject.send(:process_mqtt_photo, valid_photo_topic, binary_image_data)

        # Verify Photo.new was called with the correct params
        expect(Photo).to have_received(:new).with(
          id: "test-uuid",
          plant_module_id: plant_module.id.to_s,
          timestamp: timestamp_str
        )

        # Verify logging
        expect(Rails.logger).to have_received(:info).with("Stored photo for plant module '#{plant_module.id}'")
      end
    end

    context "with an invalid photo topic" do
      it "ignores the message and logs a warning" do
        expect {
          subject.send(:process_mqtt_photo, invalid_photo_topic, binary_image_data)
        }.not_to change(Photo, :count)
        expect(Rails.logger).to have_received(:warn).with("Ignoring message: Invalid topic format: #{invalid_photo_topic}")
      end
    end

    context "when an unexpected error occurs" do
      it "handles the exception and logs an error" do
        photo_mock = instance_double(Photo)
        image_mock = instance_double(ActiveStorage::Attached::One)

        allow(Photo).to receive(:new).and_return(photo_mock)
        allow(photo_mock).to receive(:image).and_return(image_mock)
        allow(image_mock).to receive(:attach)
        allow(photo_mock).to receive(:save!).and_raise(StandardError.new("Unexpected error"))

        expect {
          subject.send(:process_mqtt_photo, valid_photo_topic, binary_image_data)
        }.not_to raise_error

        expect(Rails.logger).to have_received(:error).with(/Unexpected error storing data/)
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
