class Photo < ApplicationRecord
  belongs_to :plant_module
  has_and_belongs_to_many :posts
end
