# frozen_string_literal: true
FactoryBot.define do
  factory :partner_plan, class: 'Partner::Plan' do
    free_plan { create(:free_plan) }
    foreign_plan_id { SecureRandom.uuid }
    name { Forgery(:lorem_ipsum).words(5, random: true).titleize }
    description { Forgery(:lorem_ipsum).words(15, random: true).capitalize }
  end

  factory :aa_stub_partner_plans, parent: :partner_plan
end
