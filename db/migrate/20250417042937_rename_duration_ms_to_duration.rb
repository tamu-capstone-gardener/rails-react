class RenameDurationMsToDuration < ActiveRecord::Migration[8.0]
  def change
    rename_column :control_executions, :duration_ms, :duration
  end
end
