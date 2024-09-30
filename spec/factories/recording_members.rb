# frozen_string_literal: true
FactoryBot.define do
  factory :recording_member do
    association :recording
    participant
    views_count { 0 }
    status { 'confirmed' }
  end

  factory :aa_stub_recording_members, parent: :recording_member
end
