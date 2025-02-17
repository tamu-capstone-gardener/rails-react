class User < ApplicationRecord
  devise :omniauthable, omniauth_providers: [:google_oauth2]

  validates :email, presence: true, uniqueness: true
  validates :username, presence: true, uniqueness: true
  
  has_many :plant_modules, primary_key: :uid, foreign_key: :user_id, dependent: :destroy

  def self.from_omniauth(auth)
    user = where(provider: auth.provider, uid: auth.uid).first_or_initialize

    user.uid = auth.uid
    user.email = auth.info.email
    user.username ||= auth.info.email.split('@').first # Default username
    user.full_name = auth.info.name
    user.avatar_url = auth.info.image
    user.provider = auth.provider
    user.save!
    user
  end
end
