# spec/system/plant_module_show_spec.rb
require "rails_helper"

RSpec.describe "PlantModule show page", type: :system do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }

  before do
    driven_by :rack_test
    sign_in user
  end

  it "renders sensors, hourly data & control signals" do
    plant_module = create(:plant_module, user: user, name: "Window Box")
    create(:care_schedule, plant_module: plant_module)
    sensor        = create(:sensor, plant_module: plant_module, measurement_type: "light_analog")
    control       = create(:control_signal, plant_module: plant_module, signal_type: "lights", label: "Test Lights")
    create(:control_execution, control_signal: control,)

    # one datapoint so the chart logic has something to aggregate
    create(:time_series_datum, sensor: sensor, value: 2048, timestamp: 1.hour.ago)

    visit plant_module_path(plant_module)

    expect(page).to have_content("Window Box")
    expect(page).to have_content("Light Analog")
    expect(page).to have_content("Test Lights")      # control signal label
  end
end
