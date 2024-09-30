# frozen_string_literal: true
FactoryBot.define do
  factory :recorded_member do
    association :abstract_session, factory: :immersive_session
    participant
    video_views_count { 0 }
    status { 'confirmed' }
  end

  factory :aa_stub_recorded_members, parent: :recorded_member
end
