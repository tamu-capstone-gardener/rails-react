class AddDurationUnitToControlExecutions < ActiveRecord::Migration[8.0]
  def change
    add_column :control_executions, :duration_unit, :string, null: false, default: "seconds"
  end
end
