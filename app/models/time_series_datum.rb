# @!attribute [r] id
#   @return [Integer] unique identifier for the time series data point
# @!attribute [rw] sensor_id
#   @return [String] UUID of the sensor this data point belongs to
# @!attribute [rw] value
#   @return [Float] measured value
# @!attribute [rw] timestamp
#   @return [DateTime] when the measurement was taken
# @!attribute [rw] notified_threshold_indices
#   @return [Array] indices of notification thresholds that have been triggered
# @!attribute [rw] created_at
#   @return [DateTime] when the record was created
# @!attribute [rw] updated_at
#   @return [DateTime] when the record was last updated
class TimeSeriesDatum < ApplicationRecord
  # @!association
  #   @return [Sensor] the sensor that produced this measurement
  belongs_to :sensor
  serialize :notified_threshold_indices, coder: ActiveRecord::Coders::YAMLColumn.new(Array)


  after_create :check_sensor_notifications

  private

  # Checks if this data point should trigger sensor notifications
  #
  # @note Enqueues a background job to handle notification processing
  # @return [void]
  def check_sensor_notifications
    # Trigger background job with sensor and data point IDs
    SensorNotificationJob.perform_later(sensor.id, id)
    # SensorMailer.with(sensor: sensor, data_point: self, message: sensor.message)
    #         .notification_email
    #         .deliver_now
  end
end
