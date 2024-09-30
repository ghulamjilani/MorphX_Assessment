# frozen_string_literal: true
FactoryBot.define do
  factory :system_user do
    association :user
  end

  factory :aa_stub_system_users, parent: :system_user
end
