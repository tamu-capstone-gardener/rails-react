class CreateControlExecutions < ActiveRecord::Migration[7.0]
  def change
    create_table :control_executions, id: :string do |t|
      t.string :control_signal_id, null: false
      t.string :source, null: false # "manual", "sensor", "schedule"
      t.integer :duration_ms, null: false
      t.datetime :executed_at, null: false

      t.timestamps
    end

    add_foreign_key :control_executions, :control_signals
    add_index :control_executions, :control_signal_id
  end
end
