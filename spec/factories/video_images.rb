# frozen_string_literal: true
FactoryBot.define do
  factory :video_image do
    video
  end

  factory :aa_stub_video_images, parent: :video_image
end
