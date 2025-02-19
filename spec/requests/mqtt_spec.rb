require 'rails_helper'

RSpec.describe MqttController, type: :request do
  let!(:valid_user) { User.create!(TestAttributes::User.valid) }
  let!(:other_user) { User.create!(TestAttributes::User.other_user) }
  let!(:plant_module) { PlantModule.create!(TestAttributes::PlantModule.valid.merge(user: valid_user)) }
  let!(:sensor) { Sensor.create!(TestAttributes::Sensor.valid.merge(plant_module: plant_module)) }
  let(:mqtt_secrets) do
    {
      url: "test.hivemq.com",
      port: 8883,
      username: "test_user",
      password: "test_password",
      topic: "test_topic"
    }
  end

  before do
    # Need this line for current error in devise functionality
    Rails.application.routes_reloader.try(:execute_unless_loaded)
    allow(Rails.application.credentials).to receive(:hivemq).and_return(mqtt_secrets)
    allow_any_instance_of(MqttController).to receive(:publish_data).and_return(true)
  end

  describe "POST /mqtt/schedule" do
    let(:valid_params) do
      {
        frequency: "daily",
        units: "hours",
        sensor_id: sensor.id
      }
    end

    context "when the user is authorized" do
      before do
        sign_in valid_user
      end
      it "sets the schedule successfully" do
        post "/mqtt/schedule", params: valid_params
        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)["status"]).to eq("success")
      end
    end

    context "when required parameters are missing" do
      before do
        sign_in valid_user
      end
      it "returns an error when frequency is missing" do
        post "/mqtt/schedule", params: valid_params.except(:frequency)
        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)["message"]).to match(/Missing one or more/)
      end
    end

    context "when the user is unauthorized" do
      before do
        sign_in other_user
      end

      it "redirects with an authorization error" do
        post "/mqtt/schedule", params: valid_params
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "POST /mqtt/water" do
    let(:valid_params) { { sensor_id: sensor.id } }

    context "when the user is authorized" do
      before do
        sign_in valid_user
      end
      it "sends the water signal successfully" do
        post "/mqtt/water", params: valid_params
        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)["status"]).to eq("success")
      end
    end

    context "when sensor_id is missing" do
      before do
        sign_in valid_user
      end
      it "returns an error" do
        post "/mqtt/water", params: {}
        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)["message"]).to match(/Missing required parameter/)
      end
    end

    context "when the user is unauthorized" do
      before do
        sign_in other_user
      end

      it "redirects with an authorization error" do
        post "/mqtt/water", params: valid_params
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
