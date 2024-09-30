# frozen_string_literal: true

FactoryBot.define do
  factory :stripe_db_plan, class: 'StripeDb::Plan' do
    sequence(:im_name) { |n| "plan-kapkan-#{n}" }
    im_color { "##{SecureRandom.hex(3)}" }
    interval_count { [1, 3, 6, 12].sample }
    interval { 'month' }
    im_enabled { true }
    active { true }
    amount { rand(999) / 100.0 * interval_count }
    association :channel_subscription, factory: :subscription
  end

  factory :all_content_included_plan, parent: :stripe_db_plan do
    im_livestreams { true }
    im_interactives { true }
    im_replays { true }
    im_uploads { true }
    im_documents { true }
    im_channel_conversation { true }
  end

  factory :fee_plan, class: 'StripeDb::Plan' do
    sequence(:im_name) { |n| "plan-kapkan-#{n}" }
    im_color { "##{SecureRandom.hex(3)}" }
    interval_count { [1, 3, 6, 12].sample }
    interval { 'month' }
    im_enabled { true }
    amount { rand(999) / 100.0 * interval_count }
  end

  factory :aa_stub_immerss_fees_plans, parent: :fee_plan
  factory :aa_stub_channel_plans, parent: :stripe_db_plan
end
