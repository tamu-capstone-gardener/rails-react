class CreateSensorNotificationLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :sensor_notification_logs do |t|
      t.references :sensor, null: false, foreign_key: true, type: :string
      t.integer :threshold_index
      t.datetime :last_sent_at

      t.timestamps
    end
  end
end
