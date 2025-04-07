class EnhanceControlSignalsForModes < ActiveRecord::Migration[7.0]
  def change
    change_table :control_signals do |t|
      t.string  :mode, null: false, default: "manual" # "manual", "automatic", "scheduled"
      t.string  :sensor_id                             # For automatic triggers
      t.string  :comparison                            # "<", ">", etc.
      t.float   :threshold_value                       # e.g., 800 for moisture
      t.integer :frequency                             # For scheduled triggers
      t.string  :unit                                  # "minutes", "hours", "days"
      t.boolean :enabled, default: true

      t.integer :length_ms                             # duration to run the signal (to be sent to ESP)
    end

    add_foreign_key :control_signals, :sensors
    add_index :control_signals, [ :sensor_id ]
  end
end
