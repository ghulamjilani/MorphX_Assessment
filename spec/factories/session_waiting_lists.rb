# frozen_string_literal: true
FactoryBot.define do
  factory :session_waiting_list do
    association :session, factory: :published_session_without_waiting
  end
end
