# @!attribute [r] id
#   @return [Integer] unique identifier for the user
# @!attribute [rw] email
#   @return [String] user's email address
# @!attribute [rw] username
#   @return [String] user's chosen username
# @!attribute [rw] full_name
#   @return [String] user's full name
# @!attribute [rw] avatar_url
#   @return [String] URL to user's avatar image
# @!attribute [rw] provider
#   @return [String] authentication provider name
# @!attribute [rw] uid
#   @return [String] unique identifier from auth provider
class User < ApplicationRecord
  devise :omniauthable, omniauth_providers: [ :google_oauth2 ]

  validates :email, presence: true, uniqueness: true
  validates :username, presence: true, uniqueness: true

  has_many :plant_modules, primary_key: :uid, foreign_key: :user_id, dependent: :destroy

  # Creates or updates a user from OAuth authentication data
  #
  # @param auth [OmniAuth::AuthHash] authentication data from OAuth provider
  # @return [User] created or updated user instance
  def self.from_omniauth(auth)
    user = where(provider: auth.provider, uid: auth.uid).first_or_initialize

    user.uid = auth.uid
    user.email = auth.info.email
    user.username ||= auth.info.email.split("@").first # Default username
    user.full_name = auth.info.name
    user.avatar_url = auth.info.image
    user.provider = auth.provider
    user.save!
    user
  end
end
