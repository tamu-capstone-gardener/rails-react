# @!attribute [r] id
#   @return [String] UUID of the control signal
# @!attribute [rw] plant_module_id
#   @return [String] ID of the plant module this control signal belongs to
# @!attribute [rw] sensor_id
#   @return [String, nil] ID of the associated sensor (optional)
# @!attribute [rw] signal_type
#   @return [String] type of control signal (e.g., "water", "light")
# @!attribute [rw] label
#   @return [String] human-readable label for the control signal
# @!attribute [rw] mode
#   @return [String] operating mode ("automatic", "manual", or "scheduled")
# @!attribute [rw] comparison
#   @return [String] comparison operator for automatic mode (e.g., "<", ">")
# @!attribute [rw] threshold_value
#   @return [Float] threshold value for automatic mode
# @!attribute [rw] length
#   @return [Integer] duration of the control signal
# @!attribute [rw] length_unit
#   @return [String] unit for the duration (e.g., "seconds", "minutes")
# @!attribute [rw] mqtt_topic
#   @return [String] MQTT topic for publishing the control signal
# @!attribute [rw] enabled
#   @return [Boolean] whether the control signal is enabled
class ControlSignal < ApplicationRecord
    # @!association
    #   @return [PlantModule] the plant module this control signal belongs to
    belongs_to :plant_module

    # @!association
    #   @return [Sensor, nil] the associated sensor (optional)
    belongs_to :sensor, optional: true

    # @!association
    #   @return [Array<ControlExecution>] execution history for this control signal
    has_many :control_executions, dependent: :destroy

    # @!association
    #   @return [ControlExecution, nil] the most recent execution of this control signal
    has_one :last_execution, -> { order(executed_at: :desc) }, class_name: "ControlExecution"

    validates :mode, presence: true
end
