require 'rails_helper'

RSpec.describe PlantRecommendationService do
  # Mock the ZIP_ZONE_MAP constant to avoid dependency on actual CSV file
  before(:all) do
    # Save original constant
    @original_zip_zone_map = ZipCodeHelper::ZIP_ZONE_MAP

    # Create test data
    test_zip_zone_map = {
      "12345" => { zone: "7a", trange: "5 to 10", zonetitle: "Zone 7a" },
      "67890" => { zone: "9b", trange: "25 to 30", zonetitle: "Zone 9b" },
      "54321" => { zone: "4b", trange: "-25 to -20", zonetitle: "Zone 4b" }
    }

    # Replace constant with test data
    ZipCodeHelper.send(:remove_const, :ZIP_ZONE_MAP)
    ZipCodeHelper.const_set(:ZIP_ZONE_MAP, test_zip_zone_map)
  end

  after(:all) do
    # Restore original constant
    ZipCodeHelper.send(:remove_const, :ZIP_ZONE_MAP)
    ZipCodeHelper.const_set(:ZIP_ZONE_MAP, @original_zip_zone_map)
  end

  let!(:indoor_plant) { create(:plant, height: 0.5, width: 0.5, edibility: "4") }
  let!(:outdoor_plant) { create(:plant, height: 0.8, width: 0.6, edibility: "5", hardiness_zones: "7-9") }
  let!(:large_plant) { create(:plant, height: 8.0, width: 5.0, edibility: "2", hardiness_zones: "7-9") }
  let!(:low_edibility_plant) { create(:plant, height: 0.6, width: 0.4, edibility: "1", hardiness_zones: "7-9") }

  describe "#recommendations" do
    context "for indoor locations" do
      it "returns all plants when no filters are applied" do
        service = described_class.new(location_type: "indoor")
        result = service.recommendations

        expect(result).to include(indoor_plant, outdoor_plant, large_plant, low_edibility_plant)
      end

      it "filters by height and width" do
        service = described_class.new(
          location_type: "indoor",
          filters: { max_height: 1.0, max_width: 1.0 }
        )
        result = service.recommendations

        expect(result).to include(indoor_plant, outdoor_plant)
        expect(result).not_to include(large_plant)
      end

      it "filters by edibility rating" do
        service = described_class.new(
          location_type: "indoor",
          filters: { edibility_rating: 4 }
        )
        result = service.recommendations

        expect(result).to include(indoor_plant, outdoor_plant)
        expect(result).not_to include(low_edibility_plant)
      end

      it "applies multiple filters together" do
        service = described_class.new(
          location_type: "indoor",
          filters: { max_height: 1.0, max_width: 1.0, edibility_rating: 4 }
        )
        result = service.recommendations

        expect(result).to include(indoor_plant, outdoor_plant)
        expect(result).not_to include(large_plant, low_edibility_plant)
      end
    end

    context "for outdoor locations" do
      it "returns all plants when no filters or zip code are applied" do
        service = described_class.new(location_type: "outdoor", zip_code: "")
        result = service.recommendations

        expect(result).to include(indoor_plant, outdoor_plant, large_plant, low_edibility_plant)
      end

      it "filters by hardiness zone based on zip code" do
        service = described_class.new(location_type: "outdoor", zip_code: "12345") # Zone 7a
        result = service.recommendations

        expect(result).to include(outdoor_plant, large_plant)
        expect(result).not_to include(indoor_plant) # Assuming indoor_plant doesn't have zone 7
      end

      it "returns no plants for invalid zip code" do
        service = described_class.new(location_type: "outdoor", zip_code: "99999") # Invalid zip
        result = service.recommendations

        expect(result).to be_empty
      end

      it "applies height, width, and edibility filters along with zip code" do
        service = described_class.new(
          location_type: "outdoor",
          zip_code: "12345", # Zone 7a
          filters: { max_height: 1.0, max_width: 1.0, edibility_rating: 4 }
        )
        result = service.recommendations

        expect(result).to include(outdoor_plant)
        expect(result).not_to include(indoor_plant, large_plant, low_edibility_plant)
      end
    end

    context "with pagination" do
      it "paginates results" do
        service = described_class.new(
          location_type: "indoor",
          filters: { page: 1 }
        )
        result = service.recommendations

        expect(result).to respond_to(:current_page)
        expect(result).to respond_to(:total_pages)
      end
    end
  end
end
