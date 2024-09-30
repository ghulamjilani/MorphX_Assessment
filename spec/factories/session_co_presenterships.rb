# frozen_string_literal: true
FactoryBot.define do
  factory :session_co_presentership do
    association :session, factory: :immersive_session
    presenter
  end
end
