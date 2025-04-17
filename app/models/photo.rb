class Photo < ApplicationRecord
  belongs_to :plant_module

  has_one_attached :image
end
