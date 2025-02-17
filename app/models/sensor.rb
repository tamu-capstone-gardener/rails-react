class Sensor < ApplicationRecord
  belongs_to :plant_module
  has_many :time_series_data, dependent: :destroy
end
