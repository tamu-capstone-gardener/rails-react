class ControlSignal < ApplicationRecord
    belongs_to :plant_module
    belongs_to :sensor, optional: true
    has_many :control_executions, dependent: :destroy

    validates :mode, presence: true
end
