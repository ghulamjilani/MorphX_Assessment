# frozen_string_literal: true
FactoryBot.define do
  factory :user_log do
    association :user, factory: :user
  end

  factory :aa_stub_user_logs, parent: :user_log
end
