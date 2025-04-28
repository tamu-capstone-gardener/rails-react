# app/models/control_execution.rb

# @!attribute [r] id
#   @return [String] UUID of the control execution
# @!attribute [rw] control_signal_id
#   @return [String] ID of the associated control signal
# @!attribute [rw] source
#   @return [String] source of the execution ("automatic", "manual", or "scheduled")
# @!attribute [rw] status
#   @return [Boolean] whether the signal was turned on (true) or off (false)
# @!attribute [rw] duration
#   @return [Integer] duration of the control signal
# @!attribute [rw] duration_unit
#   @return [String] unit for the duration (e.g., "seconds", "minutes")
# @!attribute [rw] executed_at
#   @return [DateTime] when the control was executed
# @!attribute [rw] created_at
#   @return [DateTime] when the record was created
# @!attribute [rw] updated_at
#   @return [DateTime] when the record was last updated
class ControlExecution < ApplicationRecord
  # @!association
  #   @return [ControlSignal] the control signal that was executed
  belongs_to :control_signal

  self.primary_key = "id"
  before_create :assign_uuid

  # after_create_commit do
  #   Turbo::StreamsChannel.broadcast_replace_to(
  #     "control_executions",
  #     target: "control_execution_#{control_signal_id}",
  #     partial: "control_executions/control_execution",
  #     locals: { control_execution: self }
  #   )
  # end

  private

  # Assigns a UUID to the execution if not already set
  #
  # @return [void]
  def assign_uuid
    self.id ||= SecureRandom.uuid
  end
end
