class CreateSchedules < ActiveRecord::Migration[7.0]
  def change
    create_table :schedules, id: :string do |t|
      t.string :plant_module_id, null: false
      t.integer :frequency
      t.string :unit, null: false # Enum: minutes, hours, days, weeks
      t.timestamps
    end
    add_foreign_key :schedules, :plant_modules, column: :plant_module_id
  end
end
