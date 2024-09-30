# frozen_string_literal: true
FactoryBot.define do
  factory :discount do
    name { Forgery(:basic).password }
    target_type { 'Channel' }
    target_ids { nil }
    usage_count_per_user { nil }
    usage_count_total { nil }
    expires_at { nil }
    min_amount_cents { nil }
    amount_off_cents { nil }
    percent_off_precise { Forgery(:basic).number(at_least: 5, at_most: 50) }
    is_valid { true }
  end
  factory :invalid_discount, parent: :discount do
    is_valid { false }
  end
  factory :expired_discount, parent: :discount do
    expires_at { Time.zone.now - 2.days }
  end
  factory :channel_discount, parent: :discount do
    target_type { 'Channel' }
  end
  factory :session_discount, parent: :discount do
    target_type { 'Session' }
  end
  factory :replay_discount, parent: :discount do
    target_type { 'Replay' }
  end
  factory :immersive_discount, parent: :discount do
    target_type { 'Immersive' }
  end
  factory :livestream_discount, parent: :discount do
    target_type { 'Livestream' }
  end

  factory :aa_stub_discounts, parent: :discount
end
