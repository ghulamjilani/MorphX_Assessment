# frozen_string_literal: true

FactoryBot.define do
  factory :stripe_service_plan, class: 'StripeDb::ServicePlan' do
    sequence(:nickname) { |n| "plan-kapkan-#{n}" }
    interval_count { 1 }
    interval { %w[month year].sample }
    active { true }
    amount { rand(9999) }
    currency { 'usd' }
    trial_period_days { [3, 7, 14].sample }
    stripe_id { rand(999) }
    product { rand(999) }
    association :plan_package, factory: :plan_package
  end

  factory :service_plan_with_stripe_data, parent: :stripe_service_plan do
    after(:build) do |plan|
      sth = StripeMock.create_test_helper
      product = sth.create_product(id: plan.product)
      sth.create_plan(id: plan.stripe_id, amount: plan.amount_cents, product: product.id)
    end
  end

  factory :aa_stub_stripe_db_service_plans, parent: :stripe_service_plan
end
