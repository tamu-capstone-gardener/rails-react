class ControlSignal < ApplicationRecord
    belongs_to :plant_module
    validates :signal_type, presence: true
end
