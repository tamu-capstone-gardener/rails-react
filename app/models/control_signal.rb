class ControlSignal < ApplicationRecord
    belongs_to :plant_module
    belongs_to :sensor, optional: true

    validates :mode, presence: true
end
