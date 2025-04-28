# @!attribute [r] id
#   @return [Integer] unique identifier for the schedule
# @!attribute [rw] plant_module_id
#   @return [String] ID of the plant module this schedule belongs to
# @!attribute [rw] task_type
#   @return [String] type of scheduled task
# @!attribute [rw] frequency
#   @return [Integer] how often the task should be performed
# @!attribute [rw] created_at
#   @return [DateTime] when the record was created
# @!attribute [rw] updated_at
#   @return [DateTime] when the record was last updated
class Schedule < ApplicationRecord
  # @!association
  #   @return [PlantModule] the plant module this schedule belongs to
  belongs_to :plant_module
end
