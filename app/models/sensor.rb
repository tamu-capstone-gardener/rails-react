class Sensor < ApplicationRecord
  belongs_to :plant_module
  has_many :time_series_data, dependent: :destroy

  before_create :set_uuid

  private

  def set_uuid
    self.id ||= SecureRandom.uuid
  end
end
