class CreatePlantModules < ActiveRecord::Migration[7.0]
  def change
    create_table :plant_modules, id: :string do |t|
      t.string :user_id, null: false
      t.string :name, null: false
      t.text :description
      t.string :location
      t.timestamps
    end
    add_foreign_key :plant_modules, :users, column: :user_id, primary_key: :uid
  end
end
