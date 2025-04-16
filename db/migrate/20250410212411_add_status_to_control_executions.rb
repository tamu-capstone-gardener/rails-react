class AddStatusToControlExecutions < ActiveRecord::Migration[8.0]
  def change
    add_column :control_executions, :status, :boolean, default: false, null: false
  end
end
