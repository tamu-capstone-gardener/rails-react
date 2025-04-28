require "rails_helper"

RSpec.describe "ControlSignals", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }
  let(:plant_module) { create(:plant_module, user: user) }
  let!(:care_schedule) { create(:care_schedule, plant_module: plant_module) }
  let(:control_signal) { create(:control_signal, plant_module: plant_module) }
  let!(:control_execution) { create(:control_execution, control_signal: control_signal) }
  let(:headers) { { "ACCEPT" => "text/html" } }

  before do
    Rails.application.routes_reloader.try(:execute_unless_loaded)
    sign_in user
  end

  describe "GET /plant_modules/:plant_module_id/control_signals/:id/edit" do
    it "renders the edit form" do
      get edit_plant_module_control_signal_path(plant_module, control_signal), headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(control_signal.label)
    end
  end

  describe "PATCH /plant_modules/:plant_module_id/control_signals/:id" do
    let(:update_params) do
      {
        control_signal: {
          label: "Updated Signal",
          length: 60,
          length_unit: "minutes"
        }
      }
    end

    it "updates the control signal and redirects" do
      patch plant_module_control_signal_path(plant_module, control_signal),
            params: update_params,
            headers: headers

      expect(control_signal.reload.label).to eq("Updated Signal")
      expect(control_signal.reload.length).to eq(60)
      expect(control_signal.reload.length_unit).to eq("minutes")
      expect(response).to redirect_to(plant_module_path(plant_module))
      follow_redirect!
      expect(response.body).to include("Updated Signal")
      expect(response.body).to include("60 minutes")
    end

    context "with invalid parameters" do
      let(:invalid_params) do
        {
          control_signal: {
            mode: nil # mode is required
          }
        }
      end

      it "does not update the control signal and re-renders the form" do
        original_mode = control_signal.mode

        patch plant_module_control_signal_path(plant_module, control_signal),
              params: invalid_params,
              headers: headers

        expect(control_signal.reload.mode).to eq(original_mode)
        expect(response).to have_http_status(:ok) # re-renders the form
        expect(flash[:alert]).to include("Update failed")
      end
    end
  end

  describe "POST /plant_modules/:plant_module_id/control_signals/:id/trigger" do
    let(:last_execution) { create(:control_execution, control_signal: control_signal, status: true) }

    before do
      allow(MqttListener).to receive(:publish_control_command).and_return(true)
      allow(ControlExecution).to receive(:where).and_return(double(order: double(first: last_execution)))
    end

    it "triggers the control signal with toggle=true" do
      post trigger_plant_module_control_signal_path(plant_module, control_signal),
           params: { toggle: "true" },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(MqttListener).to have_received(:publish_control_command)
                                .with(control_signal, toggle: true, mode: "manual",
                                      duration: control_signal.length, status: false)
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    end

    context "when no previous execution exists" do
      before do
        allow(ControlExecution).to receive(:where).and_return(double(order: double(first: nil)))
      end

      it "returns an unprocessable entity status" do
        post trigger_plant_module_control_signal_path(plant_module, control_signal),
             params: { toggle: "true" },
             headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash[:alert]).to include("No previous execution found")
      end
    end

    context "when an error occurs during MQTT publishing" do
      before do
        allow(MqttListener).to receive(:publish_control_command).and_raise(StandardError.new("MQTT error"))
      end

      it "returns an unprocessable entity status with error message" do
        post trigger_plant_module_control_signal_path(plant_module, control_signal),
             params: { toggle: "true" },
             headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash[:alert]).to include("Trigger failed: MQTT error")
      end
    end
  end
end
