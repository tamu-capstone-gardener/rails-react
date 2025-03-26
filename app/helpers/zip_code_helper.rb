module ZipCodeHelper
    require "csv"
    CSV_FILE_PATH = Rails.root.join("app", "assets", "csv", "phzm_us_zipcode_2023.csv")

    # Load CSV into a hash mapping zip codes to zone data.
    ZIP_ZONE_MAP = CSV.read(CSV_FILE_PATH, headers: true).each_with_object({}) do |row, hash|
      hash[row["zipcode"]] = {
        zone: row["zone"],
        trange: row["trange"],
        zonetitle: row["zonetitle"]
      }
    end.freeze

    def zone_for_zip(zip_code)
      ZIP_ZONE_MAP[zip_code]
    end

    # Optionally, you can also add a helper method here to check if a plant is in the zone.
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
