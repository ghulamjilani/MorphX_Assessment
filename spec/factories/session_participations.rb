# frozen_string_literal: true
FactoryBot.define do
  factory :session_participation do
    association :session, factory: :immersive_session
    participant
    status { 'confirmed' }
  end

  factory :aa_stub_session_participations, parent: :session_participation
end