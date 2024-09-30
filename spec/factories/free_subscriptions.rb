# frozen_string_literal: true
FactoryBot.define do
  factory :free_subscription, class: 'FreeSubscription' do
    user
    free_plan { create(:free_plan) }
  end

  factory :aa_stub_free_subscriptions, parent: :free_subscription
end
