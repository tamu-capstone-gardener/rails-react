# spec/requests/site_pages_spec.rb
require "rails_helper"

RSpec.describe "Site Pages", type: :request do
  let(:user)           { create(:user) }
  let!(:plant_module)  { create(:plant_module, user: user) }
  let!(:sensor)        { create(:sensor, plant_module: plant_module) }
  let!(:care_schedule) { create(:care_schedule, plant_module: plant_module) }
  let!(:plant)         { create(:plant) }
  let!(:ts_data)       { create(:time_series_datum, sensor: sensor) }

  describe "Public pages" do
    it "GET / (welcome)" do
      get root_path
      expect(response).to have_http_status(:ok)
    end

    it "GET /help" do
      get help_path
      expect(response).to have_http_status(:ok)
    end

    it "GET /up (health check)" do
      get rails_health_check_path
      expect(response).to have_http_status(:ok)
    end

    it "GET sign in page" do
      get new_user_session_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "Devise sign‑out" do
    before { sign_in user }

    it "signs out and redirects to sign in" do
      delete destroy_user_session_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "Authenticated pages" do
    before { sign_in user }

    describe "Profile completion" do
      it "GET /complete_profile" do
        get complete_profile_path
        expect(response).to have_http_status(:ok)
      end

      it "PATCH /complete_profile" do
        patch complete_profile_path, params: { user: { full_name: "New Name" } }
        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(flash[:notice]).to be_present
      end
    end

    describe "PlantModules pages" do
      it "GET new" do
        get new_plant_module_path
        expect(response).to have_http_status(:ok)
      end

      it "GET show" do
        get plant_module_path(plant_module)
        expect(response).to have_http_status(:ok)
      end

      it "GET edit" do
        get edit_plant_module_path(plant_module)
        expect(response).to have_http_status(:ok)
      end

      it "GET edit via nested control_signal" do
        cs = create(:control_signal, plant_module: plant_module)
        get edit_plant_module_control_signal_path(plant_module, cs)
        expect(response).to have_http_status(:ok)
      end
    end

    describe "Sensors pages" do
      it "GET show" do
        get plant_module_sensor_path(plant_module, sensor)
        expect(response).to have_http_status(:ok)
      end

      it "loads notification settings via AJAX" do
        get load_notification_settings_plant_module_sensor_path(plant_module, sensor), xhr: true
        expect(response).to have_http_status(:ok)
      end
    end

    describe "Plants pages" do
      it "GET index" do
        get plants_path
        expect(response).to have_http_status(:ok)
      end

      it "GET info" do
        get info_plant_path(plant)
        expect(response).to have_http_status(:ok)
      end
    end

    describe "Custom sensor time‑series routes" do
      it "GET sensor_time_series" do
        get sensor_time_series_path(sensor)
        expect(response).to have_http_status(:ok)
      end

      it "GET sensor_time_series_chart" do
        get sensor_time_series_chart_path(sensor)
        expect(response).to have_http_status(:ok)
      end
    end

    describe "MQTT endpoints" do
      it "POST /mqtt/schedule" do
        post "/mqtt/schedule"
        expect([ 200, 302 ]).to include(response.status)
      end

      it "POST /mqtt/water" do
        post "/mqtt/water"
        expect([ 200, 302 ]).to include(response.status)
      end
    end
  end
end
