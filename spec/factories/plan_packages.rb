# frozen_string_literal: true
FactoryBot.define do
  factory :plan_package do
    name { Forgery(:name).first_name }
    description { Forgery(:lorem_ipsum).words(3) }
    position { 1 }
  end

  factory :plan_package_with_plan, parent: :plan_package do
    after(:build) do |pp|
      create(:stripe_service_plan, interval: 'month', plan_package: pp)
    end
  end

  factory :aa_stub_plan_packages, parent: :plan_package
end
