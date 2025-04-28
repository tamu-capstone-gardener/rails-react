class AddLengthUnitToControlSignals < ActiveRecord::Migration[7.0]
  def change
    add_column :control_signals, :length_unit, :string, null: false, default: "seconds"
  end
end
