# @!attribute [r] id
#   @return [Integer] unique identifier for the plant module
# @!attribute [rw] user_id
#   @return [String] reference to the user who owns this module
# @!attribute [rw] name
#   @return [String] name of the plant module
# @!attribute [rw] location
#   @return [String] physical location of the module
# @!attribute [rw] module_mac
#   @return [String] MAC address of the hardware module
# @!attribute [rw] module_ip
#   @return [String] IP address of the hardware module
# @!attribute [rw] created_at
#   @return [DateTime] when the module was created
# @!attribute [rw] updated_at
#   @return [DateTime] when the module was last updated
class PlantModule < ApplicationRecord
  # @!association
  #   @return [User] the user who owns this module
  belongs_to :user, primary_key: :uid, foreign_key: :user_id

  # @!association
  #   @return [Array<Sensor>] sensors attached to this module
  has_many :sensors, dependent: :destroy

  # @!association
  #   @return [Array<ModulePlant>] join model between modules and plants
  has_many :module_plants, dependent: :destroy

  # @!association
  #   @return [Array<Plant>] plants contained in this module
  has_many :plants, through: :module_plants

  # @!association
  #   @return [CareSchedule] care schedule for this module
  has_one :care_schedule, dependent: :destroy

  # @!association
  #   @return [Array<Schedule>] schedules for this module
  has_many :schedules, dependent: :destroy

  # @!association
  #   @return [Array<Photo>] photos of this module
  has_many :photos, dependent: :destroy

  # @!association
  #   @return [Array<ControlSignal>] control signals for this module
  has_many :control_signals, dependent: :destroy

  # @!attribute [rw] timelapse_video
  #   @return [ActiveStorage::Attached::One] attached timelapse video file
  has_one_attached :timelapse_video
end
