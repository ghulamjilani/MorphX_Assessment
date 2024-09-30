# frozen_string_literal: true
FactoryBot.define do
  factory :session_waiting_list_membership do
    session_waiting_list
    user
  end
end
