# app/models/control_execution.rb
class ControlExecution < ApplicationRecord
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

  def assign_uuid
    self.id ||= SecureRandom.uuid
  end
end
