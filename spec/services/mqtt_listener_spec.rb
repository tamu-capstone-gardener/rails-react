require "rails_helper"
require "mqtt"

RSpec.describe MqttListener, type: :service do
  let(:user) { User.create!(TestAttributes::User.valid) }
  let(:plant_module) { PlantModule.create!(TestAttributes::PlantModule.valid.merge(user: user)) }
  let(:sensor) { Sensor.create!(TestAttributes::Sensor.valid.merge(plant_module: plant_module)) }
  let(:valid_topic) { "planthub/sensor_data/#{sensor.id}" }
  let(:invalid_topic) { "planthub/invalid_format" }
  let(:non_existent_sensor_topic) { "planthub/sensor_data/sensor-999" }
  let(:valid_message) { { "value" => 42.5, "timestamp" => "2025-02-17T12:00:00Z" }.to_json }
  let(:malformed_message) { "{invalid_json}" }
  let(:missing_field_message) { { "value" => 10.5 }.to_json }

  before do
    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:warn)
    allow(Rails.logger).to receive(:error)
  end

  describe ".process_mqtt_message" do
    it "stores valid messages correctly" do
      expect {
        described_class.process_mqtt_message(valid_topic, valid_message)
      }.to change(TimeSeriesDatum, :count).by(1)

      expect(Rails.logger).to have_received(:info).with(/Stored time series data for sensor '#{sensor.id}'/)
    end

    it "ignores messages with invalid topics" do
      expect {
        described_class.process_mqtt_message(invalid_topic, valid_message)
      }.not_to change(TimeSeriesDatum, :count)

      expect(Rails.logger).to have_received(:warn).with(/Ignoring message: Invalid topic format/)
    end

    it "rejects malformed JSON messages" do
      expect {
        described_class.process_mqtt_message(valid_topic, malformed_message)
      }.not_to change(TimeSeriesDatum, :count)

      expect(Rails.logger).to have_received(:error).with(/Malformed JSON received/)
    end

    it "ignores messages with missing required fields" do
      expect {
        described_class.process_mqtt_message(valid_topic, missing_field_message)
      }.not_to change(TimeSeriesDatum, :count)

      expect(Rails.logger).to have_received(:warn).with(/Missing required fields/)
    end

    it "handles database insertion failures gracefully" do
      allow(TimeSeriesDatum).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(TimeSeriesDatum.new))

      expect {
        described_class.process_mqtt_message(valid_topic, valid_message)
      }.not_to raise_error

      expect(Rails.logger).to have_received(:error).with(/Database insertion failed/)
    end
  end

  describe ".extract_sensor_id_from_topic" do
    it "extracts the sensor ID correctly" do
      expect(described_class.extract_sensor_id_from_topic(valid_topic)).to eq(sensor.id.to_s)
    end

    it "returns nil for an invalid topic format" do
      expect(described_class.extract_sensor_id_from_topic(invalid_topic)).to be_nil
    end
  end
end
