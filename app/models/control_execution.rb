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

  after_create_commit :broadcast_control_updates, :broadcast_flash

  private

  def broadcast_control_updates
    Rails.logger.debug "🔔 Broadcasting to control_toggle_button_#{control_signal_id}"

    pm = control_signal.plant_module

    # 1) replace the execution partial
    broadcast_replace_to(
      [ pm, :executions ],
      target: "control_execution_#{control_signal_id}",
      partial: "control_executions/control_execution",
      locals:  { signal: control_signal, control_execution: self }
    )

    # 2) replace the toggle button partial
    broadcast_replace_to(
      [ pm, :executions ],
      target: "control_toggle_button_#{control_signal_id}",
      partial: "control_signals/control_toggle_button",
      locals:  { signal: control_signal.reload }
    )
  end


  def broadcast_flash
    flash_locals =
    if status
      { notice: flash_text }
    else
      { alert:  flash_text }
    end

  broadcast_replace_to(
    :flash_messages,
    target:  "flash",
    partial: "shared/flash",
    locals:  flash_locals
  )
  end

  # Assigns a UUID to the execution if not already set
  #
  # @return [void]
  def assign_uuid
    self.id ||= SecureRandom.uuid
  end

  def flash_text
    "#{control_signal.label} turned #{status ? 'on' : 'off'} at #{executed_at.strftime("%H:%M:%S")}"
  end
end
