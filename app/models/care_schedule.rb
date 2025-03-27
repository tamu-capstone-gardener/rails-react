# app/models/care_schedule.rb
class CareSchedule < ApplicationRecord
    belongs_to :plant_module

    self.primary_key = "id"
    before_create :assign_uuid

    private

    def assign_uuid
      self.id ||= SecureRandom.uuid
    end
end
