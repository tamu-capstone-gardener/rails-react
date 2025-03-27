# app/models/module_plant.rb
class ModulePlant < ApplicationRecord
    belongs_to :plant_module
    belongs_to :plant

  # Optionally, add validations to limit the number of plants per module.
end
