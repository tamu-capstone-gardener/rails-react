# app/models/care_schedule.rb

# @!attribute [r] id
#   @return [String] UUID of the care schedule
# @!attribute [rw] plant_module_id
#   @return [String] ID of the plant module this schedule belongs to
# @!attribute [rw] watering_frequency
#   @return [Integer] how often to water in days
# @!attribute [rw] light_hours
#   @return [Integer] recommended daily light hours
# @!attribute [rw] fertilizing_frequency
#   @return [Integer] how often to fertilize in days
# @!attribute [rw] created_at
#   @return [DateTime] when the record was created
# @!attribute [rw] updated_at
#   @return [DateTime] when the record was last updated
class CareSchedule < ApplicationRecord
    # @!association
    #   @return [PlantModule] the plant module this care schedule belongs to
    belongs_to :plant_module

    self.primary_key = "id"
    before_create :assign_uuid

    private

    # Assigns a UUID to the care schedule if not already set
    #
    # @return [void]
    def assign_uuid
      self.id ||= SecureRandom.uuid
    end
end
