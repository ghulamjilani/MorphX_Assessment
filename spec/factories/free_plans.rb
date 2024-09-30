# frozen_string_literal: true
FactoryBot.define do
  factory :free_plan, class: 'FreePlan' do
    name { Forgery(:lorem_ipsum).words(5, random: true) }
    channel { create(:channel).reload }
  end

  factory :aa_stub_free_plans, parent: :free_plan
end
