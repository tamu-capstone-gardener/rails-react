class RenameLengthMsToLength < ActiveRecord::Migration[7.0]
  def change
    rename_column :control_signals, :length_ms, :length
  end
end
