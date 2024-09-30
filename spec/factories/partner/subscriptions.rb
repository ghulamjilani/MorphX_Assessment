# frozen_string_literal: true
FactoryBot.define do
  factory :partner_subscription, class: 'Partner::Subscription' do
    free_subscription { create(:free_subscription) }
    partner_plan { create(:partner_plan, free_plan: free_subscription.free_plan) }
    foreign_customer_email { Forgery(:internet).email_address }
    foreign_customer_id { SecureRandom.uuid }
    foreign_subscription_id { SecureRandom.uuid }
  end

  factory :aa_stub_partner_subscriptions, parent: :partner_subscription
end
