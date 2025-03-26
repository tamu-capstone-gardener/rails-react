# app/models/module_plant.rb
class ModulePlant < ApplicationRecord
    belongs_to :plant_module
    belongs_to :plant

    self.primary_key = "id"
    before_create :assign_uuid

    private

    def assign_uuid
      self.id ||= SecureRandom.uuid
    end
end
