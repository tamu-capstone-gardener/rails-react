class CreateSensors < ActiveRecord::Migration[7.0]
  def change
    create_table :sensors, id: :string do |t|
      t.string :plant_module_id, null: false
      t.string :measurement_unit
      t.string :measurement_type
      t.timestamps
    end
    add_foreign_key :sensors, :plant_modules, column: :plant_module_id
  end
end
