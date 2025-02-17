require "rails_helper"
require "mqtt"

RSpec.describe "MQTT Message Processor", type: :service do
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

  it "processes valid messages correctly" do
    expect {
      process_mqtt_message(valid_topic, valid_message)
    }.to change(TimeSeriesDatum, :count).by(1)

    expect(Rails.logger).to have_received(:info).with(/Stored time series data for sensor '#{sensor.id}'/)
  end

  it "ignores messages with invalid topics" do
    expect {
      process_mqtt_message(invalid_topic, valid_message)
    }.not_to change(TimeSeriesDatum, :count)

    expect(Rails.logger).to have_received(:warn).with(/Ignoring message: Invalid topic format/)
  end

  it "rejects malformed JSON messages" do
    expect {
      process_mqtt_message(valid_topic, malformed_message)
    }.not_to change(TimeSeriesDatum, :count)

    expect(Rails.logger).to have_received(:error).with(/Malformed JSON received/)
  end

  it "ignores messages with missing fields" do
    expect {
      process_mqtt_message(valid_topic, missing_field_message)
    }.not_to change(TimeSeriesDatum, :count)

    expect(Rails.logger).to have_received(:warn).with(/Missing required fields/)
  end

  it "handles database insertion failures gracefully" do
    allow(TimeSeriesDatum).to receive(:create!).and_raise(ActiveRecord::RecordInvalid)

    expect {
      process_mqtt_message(valid_topic, valid_message)
    }.not_to raise_error

    expect(Rails.logger).to have_received(:error).with(/Database insertion failed/)
  end
end
