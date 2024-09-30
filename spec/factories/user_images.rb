# frozen_string_literal: true
FactoryBot.define do
  factory :user_image do
    user
    updated_at { Time.zone.now }
    created_at { Time.zone.now }
    image_processing { false }
    crop_x { 1.1 }
    crop_y { 1.1 }
    crop_w { 1.1 }
    crop_h { 1.1 }
  end

  factory :aa_stub_user_images, parent: :user_image
end
