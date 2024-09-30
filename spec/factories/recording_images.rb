# frozen_string_literal: true
FactoryBot.define do
  factory :recording_image do
    recording
  end

  factory :aa_stub_recording_images, parent: :recording_image
end
