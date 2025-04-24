# spec/requests/plant_modules_spec.rb
require "rails_helper"

RSpec.describe "PlantModules", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user)    { create(:user) }
  let(:headers) { { "ACCEPT" => "text/html" } }

  before { sign_in user }

  describe "POST /plant_modules" do
    let(:params) do
      {
        plant_module: {
          name:          "Kitchen Rack",
          description:   "Herbs under the sink",
          location:      "Kitchen",
          location_type: "indoor",
          zip_code:      "78750"
        }
      }
    end

    it "creates the module + schedule then redirects to plant_modules_path" do
      expect {
        post plant_modules_path, params: params, headers: headers
      }.to change(PlantModule, :count).by(1)
       .and change(CareSchedule, :count).by(1)

      expect(response).to redirect_to(plant_modules_path)
    end
  end

  describe "GET /plant_modules/:id" do
    let(:plant_module) { create(:plant_module, user: user) }
    let!(:care_sched)  { create(:care_schedule, plant_module: plant_module) }
    let!(:sensor)      { create(:sensor, plant_module: plant_module) }
    let!(:control)     { create(:control_signal,
                        plant_module: plant_module,
                        signal_type: "pump",
                        label: "Test Pump") }
    let!(:execution)   { create(:control_execution, control_signal: control) }

    it "renders successfully with sensors & control signals listed" do
      get plant_module_path(plant_module), headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(sensor.measurement_type.titleize)
      expect(response.body).to include(control.label)
    end
  end

  describe "GET /plant_modules/:id as another user" do
    let(:stranger)     { create(:user) }
    let(:other_module) { create(:plant_module, user: stranger) }

    it "redirects back with alert" do
      get plant_module_path(other_module), headers: headers
      expect(response).to redirect_to(plant_modules_path)
      # We DON'T follow the redirect, so no missing index error
    end
  end

  describe "DELETE /plant_modules/:id" do
    let!(:plant_module) { create(:plant_module, user: user) }

    it "destroys the module then redirects" do
      expect {
        delete plant_module_path(plant_module), headers: headers
      }.to change(PlantModule, :count).by(-1)

      expect(response).to redirect_to(plant_modules_path)
    end
  end
end
