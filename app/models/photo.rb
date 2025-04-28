# @!attribute [r] id
#   @return [String] UUID of the photo
# @!attribute [rw] plant_module_id
#   @return [String] ID of the plant module this photo belongs to
# @!attribute [rw] timestamp
#   @return [DateTime] when the photo was taken
# @!attribute [rw] created_at
#   @return [DateTime] when the record was created
# @!attribute [rw] updated_at
#   @return [DateTime] when the record was last updated
class Photo < ApplicationRecord
  # @!association
  #   @return [PlantModule] the plant module this photo belongs to
  belongs_to :plant_module

  # @!attribute [rw] image
  #   @return [ActiveStorage::Attached::One] attached image file
  has_one_attached :image
end
