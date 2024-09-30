# frozen_string_literal: true

FactoryBot.define do
  factory :revenue_purchased_item, class: 'Reports::V1::RevenuePurchasedItem' do
    sequence(:organization_id) { |n| n }
    sequence(:channel_id) { |n| n }
    date { Time.zone.today }
    sequence(:purchased_item_id) { |n| n }
    purchased_item_type { %w[Session Video Recording StripeDb::Plan].sample }
    type { %w[immersive_access channel_subscription recorded record livestream_access].sample }
    cost { rand(100) }
    qty { rand(10) }
    gross_income { rand(100) }
    commission { rand(100) }
    income { rand(100) }
    refund { rand(100) }
    refund_system { rand(100) }
    refund_creator { rand(100) }
    total { rand(100) }
    active_at { Time.zone.now }
  end
end
