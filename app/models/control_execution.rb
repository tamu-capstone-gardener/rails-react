# app/models/control_execution.rb
class ControlExecution < ApplicationRecord
  belongs_to :control_signal

  self.primary_key = "id"
  before_create :assign_uuid

  private

  def assign_uuid
    self.id ||= SecureRandom.uuid
  end
end
