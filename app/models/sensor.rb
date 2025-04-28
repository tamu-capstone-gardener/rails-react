# @!attribute [r] id
#   @return [String] UUID of the sensor
# @!attribute [rw] plant_module_id
#   @return [String] ID of the plant module this sensor belongs to
# @!attribute [rw] measurement_type
#   @return [String] type of measurement (e.g., "moisture", "temperature")
# @!attribute [rw] measurement_unit
#   @return [String] unit of measurement (e.g., "Celsius", "%")
# @!attribute [rw] created_at
#   @return [DateTime] when the sensor was created
# @!attribute [rw] updated_at
#   @return [DateTime] when the sensor was last updated
class Sensor < ApplicationRecord
  # @!association
  #   @return [PlantModule] the plant module this sensor belongs to
  belongs_to :plant_module

  # @!association
  #   @return [Array<TimeSeriesDatum>] time series data collected by this sensor
  has_many :time_series_data, dependent: :destroy

  before_create :set_uuid

  private

  # Sets a UUID for the sensor if not already set
  #
  # @return [void]
  def set_uuid
    self.id ||= SecureRandom.uuid
  end
end
