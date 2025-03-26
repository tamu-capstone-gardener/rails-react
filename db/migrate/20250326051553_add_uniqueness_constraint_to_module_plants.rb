class AddUniquenessConstraintToModulePlants < ActiveRecord::Migration[7.0]
  def change
    add_index :module_plants, [ :plant_module_id, :plant_id ], unique: true, name: 'index_unique_module_plants'
  end
end
