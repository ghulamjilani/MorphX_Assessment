# frozen_string_literal: true
FactoryBot.define do
  factory :livestreamer do
    association :session, factory: :immersive_session
    participant
    status { 'confirmed' }
  end
  factory :aa_stub_livestreamers, parent: :livestreamer
end
