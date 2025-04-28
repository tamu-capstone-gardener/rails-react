# @!attribute [r] id
#   @return [Integer] unique identifier for the notification log
# @!attribute [rw] sensor_id
#   @return [String] ID of the sensor that triggered the notification
# @!attribute [rw] message
#   @return [String] notification message
# @!attribute [rw] value
#   @return [Float] sensor value that triggered the notification
# @!attribute [rw] threshold
#   @return [Float] threshold that was crossed
# @!attribute [rw] created_at
#   @return [DateTime] when the notification was created
# @!attribute [rw] updated_at
#   @return [DateTime] when the notification was last updated
class SensorNotificationLog < ApplicationRecord
  # @!association
  #   @return [Sensor] the sensor that triggered this notification
  belongs_to :sensor
end
