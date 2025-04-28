# app/models/module_plant.rb

# @!attribute [r] id
#   @return [String] UUID of the module plant association
# @!attribute [rw] plant_module_id
#   @return [String] ID of the plant module
# @!attribute [rw] plant_id
#   @return [Integer] ID of the plant
# @!attribute [rw] created_at
#   @return [DateTime] when the record was created
# @!attribute [rw] updated_at
#   @return [DateTime] when the record was last updated
class ModulePlant < ApplicationRecord
    # @!association
    #   @return [PlantModule] the plant module in this association
    belongs_to :plant_module
    
    # @!association
    #   @return [Plant] the plant in this association
    belongs_to :plant

    self.primary_key = "id"
    before_create :assign_uuid

    private

    # Assigns a UUID to the association if not already set
    #
    # @return [void]
    def assign_uuid
      self.id ||= SecureRandom.uuid
    end
end
