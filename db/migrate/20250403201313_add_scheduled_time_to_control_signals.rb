class AddScheduledTimeToControlSignals < ActiveRecord::Migration[8.0]
  def change
    add_column :control_signals, :scheduled_time, :time
  end
end
