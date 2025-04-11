class ControlSignal < ApplicationRecord
    belongs_to :plant_module
    belongs_to :sensor, optional: true
    has_many :control_executions, dependent: :destroy

    has_one :last_execution, -> { order(executed_at: :desc) }, class_name: "ControlExecution"
    validates :mode, presence: true
end
