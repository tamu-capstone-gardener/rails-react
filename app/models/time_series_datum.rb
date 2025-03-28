class TimeSeriesDatum < ApplicationRecord
  belongs_to :sensor

  after_create :check_sensor_notifications

  private

  def check_sensor_notifications
    # Trigger background job with sensor and data point IDs
    SensorNotificationJob.perform_later(sensor.id, id)
    # SensorMailer.with(sensor: sensor, data_point: self, message: sensor.message)
    #         .notification_email
    #         .deliver_now

  end
end
