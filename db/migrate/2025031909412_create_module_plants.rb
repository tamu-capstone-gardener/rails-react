class CreateModulePlants < ActiveRecord::Migration[8.0]
    def change
      create_table :module_plants, id: :string do |t|
        t.string :plant_module_id, null: false
        t.string :plant_id, null: false

        t.timestamps
      end

      add_foreign_key :module_plants, :plant_modules
      add_foreign_key :module_plants, :plants
    end
end
