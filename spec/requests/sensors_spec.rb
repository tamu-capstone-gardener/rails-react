# spec/requests/sensors_spec.rb
require "rails_helper"

RSpec.describe "Sensors", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:user) { create(:user) }
  let(:plant_module) { create(:plant_module, user: user) }
  let(:sensor) { create(:sensor, plant_module: plant_module, measurement_type: "temperature") }
  let(:headers) { { "ACCEPT" => "text/html" } }

  before do
    Rails.application.routes_reloader.try(:execute_unless_loaded)
    sign_in user
  end

  describe "GET /plant_modules/:plant_module_id/sensors/:id" do
    before do
      # Create some time series data for the sensor
      10.times do |i|
        create(:time_series_datum,
          sensor: sensor,
          timestamp: i.hours.ago,
          value: 20 + i
        )
      end
    end

    it "renders successfully with default time range" do
      get plant_module_sensor_path(plant_module, sensor), headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(sensor.measurement_type.titleize)
    end

    it "renders successfully with custom days parameter" do
      get plant_module_sensor_path(plant_module, sensor, days: 5), headers: headers

      expect(response).to have_http_status(:ok)
    end

    it "renders successfully with start_date parameter" do
      get plant_module_sensor_path(plant_module, sensor, start_date: 3.days.ago.to_date.to_s), headers: headers

      expect(response).to have_http_status(:ok)
    end

    it "handles turbo_stream format" do
      get plant_module_sensor_path(plant_module, sensor, format: :turbo_stream), headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq "text/vnd.turbo-stream.html"
    end
  end

  describe "PATCH /plant_modules/:plant_module_id/sensors/:id/toggle_notification" do
    it "toggles notification setting to true" do
      sensor.update(notifications: false)

      patch toggle_notification_plant_module_sensor_path(plant_module, sensor, format: :turbo_stream), headers: headers

      expect(response).to have_http_status(:ok)
      expect(sensor.reload.notifications).to be true
    end

    it "toggles notification setting to false" do
      sensor.update(notifications: true)

      patch toggle_notification_plant_module_sensor_path(plant_module, sensor, format: :turbo_stream), headers: headers

      expect(response).to have_http_status(:ok)
      expect(sensor.reload.notifications).to be false
    end

    it "handles HTML format with redirect" do
      patch toggle_notification_plant_module_sensor_path(plant_module, sensor), headers: headers

      expect(response).to redirect_to(plant_module_sensor_path(plant_module, sensor))
    end
  end

  describe "PATCH /plant_modules/:plant_module_id/sensors/:id/update_notification_settings" do
    let(:notification_params) do
      {
        comparisons: [ ">", "<" ],
        values: [ "25", "10" ],
        messages: [ "Too hot!", "Too cold!" ],
        sensor: { notifications: "1" }
      }
    end

    it "updates the notification settings" do
      patch update_notification_settings_plant_module_sensor_path(plant_module, sensor, format: :turbo_stream),
        params: notification_params,
        headers: headers

      expect(response).to have_http_status(:ok)
      sensor.reload
      expect(sensor.thresholds).to eq([ "> 25", "< 10" ])
      expect(sensor.messages).to eq([ "Too hot!", "Too cold!" ])
      expect(sensor.notifications).to be true
    end

    it "handles HTML format with redirect" do
      patch update_notification_settings_plant_module_sensor_path(plant_module, sensor),
        params: notification_params,
        headers: headers

      expect(response).to redirect_to(plant_module_sensor_path(plant_module, sensor))
    end
  end

  describe "GET /plant_modules/:plant_module_id/sensors/:id/load_notification_settings" do
    it "renders the notification form partial" do
      get load_notification_settings_plant_module_sensor_path(plant_module, sensor), headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("notification_modal_frame")
    end
  end

  describe "GET /sensors/:id/time_series_chart" do
    let!(:light_sensor) { create(:sensor, plant_module: plant_module, measurement_type: "light_analog") }

    before do
      # Create some time series data spanning multiple days
      48.times do |i|
        create(:time_series_datum,
          sensor: sensor,
          timestamp: i.hours.ago,
          value: 22 + (i % 10)
        )

        create(:time_series_datum,
          sensor: light_sensor,
          timestamp: i.hours.ago,
          value: 2000 + (i % 500)
        )
      end
    end

    it "renders chart data for default range" do
      get sensor_time_series_chart_path(sensor, format: :turbo_stream), headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq "text/vnd.turbo-stream.html"
    end

    it "renders chart data for 1 day range" do
      get sensor_time_series_chart_path(sensor, range: "1_day", format: :turbo_stream), headers: headers

      expect(response).to have_http_status(:ok)
    end

    it "renders chart data for 7 days range" do
      get sensor_time_series_chart_path(sensor, range: "7_days", format: :turbo_stream), headers: headers

      expect(response).to have_http_status(:ok)
    end

    it "handles light sensor data transformation" do
      get sensor_time_series_chart_path(light_sensor, format: :turbo_stream), headers: headers

      expect(response).to have_http_status(:ok)
    end
  end
end
