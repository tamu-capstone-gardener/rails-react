# Helper module for working with ZIP codes and plant hardiness zones
#
# This module provides methods to look up USDA hardiness zones by ZIP code
# and determine if plants can grow in particular zones.
module ZipCodeHelper
    require "csv"

    # Path to the CSV file containing ZIP code to hardiness zone mappings
    # @return [Pathname] path to the CSV file
    CSV_FILE_PATH = Rails.root.join("app", "assets", "csv", "phzm_us_zipcode_2023.csv")

    # Map of ZIP codes to hardiness zone data
    # @return [Hash<String, Hash>] mapping from ZIP codes to zone information
    # @option [String] :zone USDA hardiness zone (e.g., "Zone 7a")
    # @option [String] :trange temperature range for the zone
    # @option [String] :zonetitle descriptive title for the zone
    ZIP_ZONE_MAP = CSV.read(CSV_FILE_PATH, headers: true).each_with_object({}) do |row, hash|
      hash[row["zipcode"]] = {
        zone: row["zone"],
        trange: row["trange"],
        zonetitle: row["zonetitle"]
      }
    end.freeze

    # Gets hardiness zone data for a ZIP code
    #
    # @param zip_code [String] the ZIP code to look up
    # @return [Hash, nil] zone data if found, nil otherwise
    # @option [String] :zone USDA hardiness zone (e.g., "Zone 7a")
    # @option [String] :trange temperature range for the zone
    # @option [String] :zonetitle descriptive title for the zone
    def zone_for_zip(zip_code)
      ZIP_ZONE_MAP[zip_code]
    end

    # Determines if a plant can grow in the hardiness zone of a given ZIP code
    #
    # @param plant [Plant] the plant to check
    # @param zip_code [String] the ZIP code to check against
    # @return [Boolean] true if the plant can grow in the zone, false otherwise
    def plant_in_zone?(plant, zip_code)
      return false if zip_code.blank?
      zone_data = zone_for_zip(zip_code)
      return false unless zone_data
      zone_num = zone_data[:zone].match(/\d+/)[0].to_i
      # Assuming plant.hardiness_zones is stored as a JSON array like "[4,5,6,7,8]"
      plant_zones = JSON.parse(plant.hardiness_zones) rescue []
      plant_zones.include?(zone_num)
    end
end
