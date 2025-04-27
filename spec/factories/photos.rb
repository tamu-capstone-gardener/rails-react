FactoryBot.define do
  factory :photo do
    association :plant_module

    # Use after_create callback to attach a test image
    after(:build) do |photo|
      # This doesn't actually attach a file, but the attachment will appear to exist
      # Which is what we need for our test mocks
      photo.define_singleton_method(:image) do
        AttachmentProxy.new
      end
    end
  end
end

# Simple class to mimic ActiveStorage attachment behavior
class AttachmentProxy
  def attached?
    true
  end
end
