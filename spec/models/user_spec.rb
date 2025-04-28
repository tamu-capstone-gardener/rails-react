require 'rails_helper'

RSpec.describe User, type: :model do
  # Factory validity test
  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:user)).to be_valid
    end
  end

  # Validations tests
  describe 'validations' do
    it 'requires an email' do
      user = build(:user, email: nil)
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("can't be blank")
    end

    it 'requires a unique email' do
      original = create(:user)
      duplicate = build(:user, email: original.email)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:email]).to include("has already been taken")
    end

    it 'requires a username' do
      user = build(:user, username: nil)
      expect(user).not_to be_valid
      expect(user.errors[:username]).to include("can't be blank")
    end

    it 'requires a unique username' do
      original = create(:user)
      duplicate = build(:user, username: original.username)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:username]).to include("has already been taken")
    end
  end

  # Associations tests
  describe 'associations' do
    it 'has many plant modules' do
      association = User.reflect_on_association(:plant_modules)
      expect(association.macro).to eq(:has_many)
    end

    it 'destroys dependent plant modules' do
      association = User.reflect_on_association(:plant_modules)
      expect(association.options[:dependent]).to eq(:destroy)
    end
  end

  # OmniAuth helper method test
  describe '.from_omniauth' do
    let(:auth) do
      OmniAuth::AuthHash.new({
        provider: 'google_oauth2',
        uid: '123456789',
        info: {
          email: 'test@example.com',
          name: 'Test User',
          image: 'http://example.com/avatar.jpg'
        }
      })
    end

    context 'when user does not exist' do
      it 'creates a new user' do
        expect { User.from_omniauth(auth) }.to change(User, :count).by(1)
      end

      it 'sets correct attributes' do
        user = User.from_omniauth(auth)

        expect(user.provider).to eq('google_oauth2')
        expect(user.uid).to eq('123456789')
        expect(user.email).to eq('test@example.com')
        expect(user.username).to eq('test')
        expect(user.full_name).to eq('Test User')
        expect(user.avatar_url).to eq('http://example.com/avatar.jpg')
      end
    end

    context 'when user already exists' do
      before do
        create(:user, provider: 'google_oauth2', uid: '123456789', email: 'existing@example.com')
      end

      it 'does not create a new user' do
        expect { User.from_omniauth(auth) }.not_to change(User, :count)
      end

      it 'updates user attributes' do
        user = User.from_omniauth(auth)

        expect(user.email).to eq('test@example.com')
        expect(user.full_name).to eq('Test User')
        expect(user.avatar_url).to eq('http://example.com/avatar.jpg')
      end
    end
  end
end
