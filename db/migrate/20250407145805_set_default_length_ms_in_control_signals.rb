class SetDefaultLengthMsInControlSignals < ActiveRecord::Migration[7.0]
  def change
    change_column_default :control_signals, :length_ms, from: nil, to: 3000
  end
end
