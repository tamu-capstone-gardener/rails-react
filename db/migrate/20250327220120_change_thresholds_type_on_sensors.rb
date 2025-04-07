class ChangeThresholdsTypeOnSensors < ActiveRecord::Migration[8.0]
  def change
    remove_column :sensors, :thresholds
    add_column :sensors, :thresholds, :string, array: true, default: []
  end
end
