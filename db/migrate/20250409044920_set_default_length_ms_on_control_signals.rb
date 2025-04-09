class SetDefaultLengthMsOnControlSignals < ActiveRecord::Migration[7.0]
  def change
    change_column_default :control_signals, :length_ms, 3000
  end
end
