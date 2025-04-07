class AddHardwareConfigAndControls < ActiveRecord::Migration[7.0]
  def change
    add_column :plant_modules, :hardware_config, :jsonb, default: {}

    create_table :control_signals, id: :string do |t|
      t.string :plant_module_id, null: false
      t.string :signal_type, null: false  # pump, light, outlet, etc.
      t.string :label
      t.string :mqtt_topic
      t.integer :delay, default: 3000
      t.timestamps
    end

    add_foreign_key :control_signals, :plant_modules
    add_index :control_signals, [ :plant_module_id, :signal_type ]
  end
end
