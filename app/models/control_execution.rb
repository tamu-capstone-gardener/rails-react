# app/models/control_execution.rb
class ControlExecution < ApplicationRecord
  belongs_to :control_signal

  self.primary_key = "id"
  before_create :assign_uuid

  after_create_commit do
    broadcast_replace_to "control_executions",
      target: ActionController::Base.helpers.dom_id(self),
      partial: "control_executions/control_execution",
      locals: { control_execution: self }
  end

  private

  def assign_uuid
    self.id ||= SecureRandom.uuid
  end
end
