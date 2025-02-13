class CreateTimeSeriesData < ActiveRecord::Migration[7.0]
  def change
    create_table :time_series_data do |t|
      t.string :sensor_id, null: false
      t.timestamp :timestamp, null: false
      t.float :value, null: false
      t.timestamps
    end
    add_foreign_key :time_series_data, :sensors, column: :sensor_id
  end
end
