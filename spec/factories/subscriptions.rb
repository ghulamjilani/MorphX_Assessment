# frozen_string_literal: true
FactoryBot.define do
  factory :subscription do
    association :channel, factory: :channel
    description { 'MyText' }
    after(:build) do |subscription|
      subscription.user = subscription.channel.organizer
    end

    after(:create) do |subscription|
      subscription.channel.create_stripe_product!
    end
  end

  factory :aa_stub_subscriptions, parent: :subscription
  factory :aa_stub_channel_subscriptions, parent: :subscription
  factory :aa_stub_channel_subscription_packages, parent: :subscription
end
