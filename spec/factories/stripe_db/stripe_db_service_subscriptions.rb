# frozen_string_literal: true

FactoryBot.define do
  factory :stripe_service_subscription, class: 'StripeDb::ServiceSubscription' do
    association :stripe_plan, factory: :stripe_service_plan
    association :organization, factory: :organization
    user { organization.user }
    status { 'active' }
    service_status { 'active' }
    stripe_id { rand(1000) }
  end
  factory :aa_stub_stripe_db_service_subscriptions, parent: :stripe_service_subscription
  factory :aa_stub_service_subscriptions, parent: :stripe_service_subscription
end
