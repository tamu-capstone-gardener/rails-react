class AddNotifiedThresholdIndicesToTimeSeriesData < ActiveRecord::Migration[8.0]
  def change
    add_column :time_series_data, :notified_threshold_indices, :text, default: "--- []\n"
  end
end
