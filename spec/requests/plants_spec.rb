require 'rails_helper'

RSpec.describe "Plants", type: :request do
  describe "GET /plants" do
    let!(:plant1) { create(:plant, common_name: "Rose", genus: "Rosa", species: "Rosa x") }
    let!(:plant2) { create(:plant, common_name: "Sunflower", genus: "Helianthus", species: "Helianthus annuus") }
    let!(:plant3) { create(:plant, common_name: "Maple Tree", genus: "Acer", species: "Acer rubrum", height: 20.0, width: 15.0) }

    context "with search query" do
      it "returns plants matching the query" do
        get "/plants", params: { query: "rose" }
        expect(response).to have_http_status(200)
        expect(response.body).to include("Rose")
        expect(response.body).not_to include("Sunflower")
      end
    end

    context "with turbo frame request" do
      it "renders the recommendations partial" do
        get "/plants", params: {}, headers: { "Turbo-Frame" => "plant_recommendations" }
        expect(response).to have_http_status(200)
        expect(response.body).to include("Rose")
        expect(response.body).to include("Sunflower")
      end
    end

    context "with indoor location type" do
      it "includes plants regardless of height and width constraints" do
        get "/plants", params: { location_type: "indoor", max_height: 10.0, max_width: 10.0 }
        expect(response).to have_http_status(200)
        expect(response.body).to include("Rose")
        expect(response.body).to include("Sunflower")
        expect(response.body).to include("Maple Tree")
      end
    end

    context "with outdoor location type" do
      before do
        allow_any_instance_of(ZipCodeHelper).to receive(:zone_for_zip).with("12345").and_return({ zone: "Zone 6a" })
      end

      it "filters plants by zip code" do
        get "/plants", params: { location_type: "outdoor", zip_code: "12345" }
        expect(response).to have_http_status(200)
      end
    end
  end

  describe "GET /plants/:id/info" do
    let!(:plant) { create(:plant, common_name: "Lavender", genus: "Lavandula") }

    it "returns plant info partial" do
      get "/plants/#{plant.id}/info"
      expect(response).to have_http_status(200)
      expect(response.body).to include("Lavender")
    end
  end
end
