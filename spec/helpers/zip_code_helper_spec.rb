require 'rails_helper'

RSpec.describe ZipCodeHelper, type: :helper do
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

  describe '#zone_for_zip' do
    it 'returns zone data for a valid zip code' do
      expect(helper.zone_for_zip('12345')).to eq({ zone: "7a", trange: "5 to 10", zonetitle: "Zone 7a" })
    end

    it 'returns nil for an invalid zip code' do
      expect(helper.zone_for_zip('99999')).to be_nil
    end

    it 'returns nil for nil input' do
      expect(helper.zone_for_zip(nil)).to be_nil
    end
  end

  describe '#plant_in_zone?' do
    let(:plant_zone_4_to_7) {
      double('Plant', hardiness_zones: '[4,5,6,7]')
    }

    let(:plant_zone_8_to_10) {
      double('Plant', hardiness_zones: '[8,9,10]')
    }

    let(:plant_with_invalid_zones) {
      double('Plant', hardiness_zones: 'not_json_array')
    }

    it 'returns true when plant zone includes zip code zone' do
      expect(helper.plant_in_zone?(plant_zone_4_to_7, '54321')).to be true  # Zone 4b
      expect(helper.plant_in_zone?(plant_zone_4_to_7, '12345')).to be true  # Zone 7a
    end

    it 'returns false when plant zone does not include zip code zone' do
      expect(helper.plant_in_zone?(plant_zone_4_to_7, '67890')).to be false  # Zone 9b
      expect(helper.plant_in_zone?(plant_zone_8_to_10, '12345')).to be false # Zone 7a
    end

    it 'returns false for invalid zip code' do
      expect(helper.plant_in_zone?(plant_zone_4_to_7, '99999')).to be false
    end

    it 'returns false for nil zip code' do
      expect(helper.plant_in_zone?(plant_zone_4_to_7, nil)).to be false
    end

    it 'returns false for blank zip code' do
      expect(helper.plant_in_zone?(plant_zone_4_to_7, '')).to be false
    end

    it 'returns false when plant has invalid hardiness_zones data' do
      expect(helper.plant_in_zone?(plant_with_invalid_zones, '12345')).to be false
    end

    it 'handles zone with letter suffix correctly' do
      # '12345' is zone 7a which should match a plant that grows in zone 7
      expect(helper.plant_in_zone?(plant_zone_4_to_7, '12345')).to be true
    end
  end
end
