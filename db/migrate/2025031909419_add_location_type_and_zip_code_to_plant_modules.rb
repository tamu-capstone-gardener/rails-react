class AddLocationTypeAndZipCodeToPlantModules < ActiveRecord::Migration[8.0]
    def change
      add_column :plant_modules, :location_type, :string, null: false, default: "indoor"
      add_column :plant_modules, :zip_code, :string
    end
  end
  