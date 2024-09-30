# frozen_string_literal: true

FactoryBot.define do
  factory :stripe_db_subscription, class: 'StripeDb::Subscription' do
    stripe_plan factory: :stripe_db_plan
    user factory: :user
    status { 'active' }
    stripe_id { rand(1000) }
  end
  factory :aa_stub_stripe_subscriptions, parent: :stripe_db_subscription
end
