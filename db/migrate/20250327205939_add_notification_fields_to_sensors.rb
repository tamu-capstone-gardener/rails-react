class AddNotificationFieldsToSensors < ActiveRecord::Migration[8.0]
  def change
    add_column :sensors, :notifications, :boolean, default: false, null: false
    add_column :sensors, :thresholds, :float, array: true, default: []
    add_column :sensors, :messages, :string, array: true, default: []
  end
end
