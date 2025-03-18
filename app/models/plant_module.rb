class PlantModule < ApplicationRecord
  belongs_to :user, primary_key: :uid, foreign_key: :user_id
  has_many :sensors, dependent: :destroy
  has_many :schedules, dependent: :destroy
  has_many :photos, dependent: :destroy
end
